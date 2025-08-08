namespace :transactions do
  desc "Replay transaction log to reconstruct state"
  task replay: :environment do
    puts "Transaction Log State Replay"
    puts "=" * 50
    
    # Get time range from environment variables
    from_date = ENV['FROM'] ? Date.parse(ENV['FROM']) : nil
    to_date = ENV['TO'] ? Date.parse(ENV['TO']) : nil
    
    if from_date || to_date
      puts "Replaying transactions from #{from_date || 'beginning'} to #{to_date || 'now'}"
    else
      puts "Replaying all transactions"
    end
    
    # Replay the state
    state = Transaction.replay_state(from: from_date, to: to_date)
    
    # Display summary
    puts "\nSummary:"
    puts "-" * 30
    puts "Total events processed: #{state[:summary][:total_events]}"
    puts "\nEvents by type:"
    state[:summary][:events_by_type].each do |event_type, count|
      puts "  #{event_type}: #{count}"
    end
    
    # Display certificate state
    if state[:certificates].any?
      puts "\nCertificates:"
      puts "-" * 30
      state[:certificates].each do |cert_id, cert_state|
        cert = Certificate.find_by(id: cert_id)
        if cert
          puts "  Certificate ##{cert_id} (#{cert.sn_base}):"
          puts "    Quantity: #{cert_state[:quantity]}"
          puts "    Created: #{cert_state[:created_at]}"
        end
      end
    end
    
    # Display certificate quantities state
    if state[:certificate_quantities].any?
      puts "\nCertificate Quantities:"
      puts "-" * 30
      
      # Group by status
      by_status = state[:certificate_quantities].group_by { |_, cq| cq[:status] }
      
      by_status.each do |status, quantities|
        puts "  Status: #{status}"
        total = quantities.sum { |_, cq| cq[:quantity] || 0 }
        puts "    Count: #{quantities.count}"
        puts "    Total Quantity: #{total}"
      end
    end
    
    puts "\nReplay completed successfully!"
  end
  
  desc "Verify transaction log integrity"
  task verify: :environment do
    puts "Verifying Transaction Log Integrity"
    puts "=" * 50
    
    errors = []
    
    # Check for any updated records (should be none)
    updated_count = Transaction.where('updated_at != created_at').count
    if updated_count > 0
      errors << "Found #{updated_count} transaction records that have been updated"
    end
    
    # Check for duplicate transaction IDs
    duplicates = Transaction.group(:transaction_id)
                            .having('COUNT(*) > 1')
                            .pluck(:transaction_id)
    if duplicates.any?
      errors << "Found duplicate transaction IDs: #{duplicates.join(', ')}"
    end
    
    # Verify all successful certificate operations have corresponding log entries
    CertificateQuantity.find_each do |cq|
      log_count = Transaction.where(certificate_quantity_id: cq.id).count
      if log_count == 0 && cq.created_at > Transaction.minimum(:created_at).to_date
        errors << "CertificateQuantity ##{cq.id} has no transaction log entries"
      end
    end
    
    if errors.any?
      puts "Integrity Check FAILED:"
      errors.each { |error| puts "  - #{error}" }
      exit 1
    else
      puts "Integrity check PASSED"
      puts "  Total transactions: #{Transaction.count}"
      puts "  Successful: #{Transaction.successful.count}"
      puts "  Failed: #{Transaction.failed.count}"
      puts "  Date range: #{Transaction.minimum(:created_at)} to #{Transaction.maximum(:created_at)}"
    end
  end
  
  desc "Generate transaction report"
  task report: :environment do
    org_id = ENV['ORG_ID']
    days = (ENV['DAYS'] || 30).to_i
    
    puts "Transaction Report"
    puts "=" * 50
    
    scope = Transaction.where('created_at > ?', days.days.ago)
    scope = scope.for_organization(org_id) if org_id
    
    puts "Period: Last #{days} days"
    puts "Organization: #{org_id ? Organization.find(org_id).name : 'All'}"
    puts "-" * 30
    
    # Activity by day
    puts "\nDaily Activity:"
    by_day = scope.group("DATE(created_at)")
                  .group(:event_type)
                  .count
    
    by_day.group_by { |(date, _), _| date }.each do |date, events|
      puts "\n#{date}:"
      events.each do |(_, event_type), count|
        puts "  #{event_type}: #{count}"
      end
    end
    
    # Top users
    puts "\nTop Users by Activity:"
    scope.joins(:user)
         .group('users.id')
         .count
         .sort_by { |_, count| -count }
         .first(10)
         .each do |user_id, count|
           user = User.find(user_id)
           puts "  #{user.organization.name}: #{count} transactions"
         end
    
    # Error analysis
    failed = scope.failed
    if failed.any?
      puts "\nFailed Transactions:"
      puts "  Total: #{failed.count}"
      
      by_type = failed.group(:event_type).count
      puts "  By type:"
      by_type.each do |event_type, count|
        puts "    #{event_type}: #{count}"
      end
    end
  end
end
