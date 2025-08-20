namespace :certificate_quantities do
  desc "Queue stale transfers finder job to clear stale transfers"
  task queue_stale_transfers_job: :environment do
    Sidekiq::Cron::Job.create(
      name: 'StaleTransfersFinderJob - every 1hr',
      cron: '0 */1 * * *', # once an hour on the hour -- https://crontab.guru/#0_*/1_*_*_*
      class: 'StaleTransfersFinderJob'
    )
  end
end
