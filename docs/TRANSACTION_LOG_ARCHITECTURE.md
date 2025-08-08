# Transaction Log & Concurrency Control Architecture

## Overview

This system implements a comprehensive transaction logging mechanism with pessimistic locking to ensure data integrity and provide a complete audit trail for all certificate operations.

## Key Components

### 1. Transaction Model (`app/models/transaction.rb`)
- **Append-only log**: Records cannot be updated or deleted once created
- **Comprehensive tracking**: Captures all state changes with before/after values
- **Event types**: 
  - `certificate_issued`
  - `certificate_split`
  - `certificate_transfer_initiated`
  - `certificate_transfer_accepted`
  - `certificate_transfer_cancelled`
  - `certificate_retired`
  - `generation_created`

### 2. TransactionLogger Service (`app/services/transaction_logger.rb`)
- Centralized logging interface
- Captures request context (user, IP, request ID)
- Error logging with stack traces
- Consistent logging format across all operations

### 3. Pessimistic Locking Strategy
- Uses database row-level locking via ActiveRecord's `lock!` method
- Prevents concurrent modifications to the same certificate quantity
- Re-validates conditions after acquiring locks
- All operations wrapped in database transactions

## Concurrency Protection

### How It Works
1. **Lock Acquisition**: Each operation calls `lock!` on the record being modified
2. **Condition Re-check**: After lock is acquired, conditions are re-validated
3. **Atomic Operations**: All changes occur within a single database transaction
4. **Automatic Rollback**: Any failure rolls back all changes

### Example: Concurrent Split Prevention
```ruby
# Two users try to split the same certificate simultaneously
# User A: Split 100 from 150 (wants 100 + 50)
# User B: Split 80 from 150 (wants 80 + 70)

# Without locking: Both could succeed, creating invalid state
# With locking: First request succeeds, second fails with error
```

## State Replay Mechanism

The transaction log enables complete state reconstruction at any point in time:

```ruby
# Replay all successful transactions
state = Transaction.replay_state

# Replay transactions for a specific time range
state = Transaction.replay_state(
  from: 1.month.ago,
  to: Date.today
)

# Returns a hash with:
# - certificates: Current state of all certificates
# - certificate_quantities: Current state of all quantities
# - accounts: Account balances
# - summary: Event counts and statistics
```

## Database Schema

### Transaction Table Structure
- **Event identification**: `event_type`, `transaction_id`
- **Actor tracking**: `user_id`, `organization_id`
- **Resource references**: Links to affected records
- **Quantity tracking**: `quantity_before`, `quantity_after`, `quantity_changed`
- **Status tracking**: `status_before`, `status_after`
- **Metadata**: JSON field for additional context
- **Error handling**: `error_message`, `success` flag

### Indexes for Performance
- Unique index on `transaction_id`
- Indexes on all foreign keys
- Composite index on `[event_type, created_at]`
- Index on `request_id` for request tracing

## Usage Examples

### In Controllers
```ruby
class CertificateQuantitiesController < ApplicationController
  before_action :initialize_logger
  
  def split
    @certificate_quantity = CertificateQuantity.find(params[:id])
    @certificate_quantity.split(quantity, logger: @transaction_logger)
  end
  
  private
  
  def initialize_logger
    @transaction_logger = TransactionLogger.new(
      user: current_user,
      organization: current_user.organization,
      request_id: request.request_id,
      ip_address: request.remote_ip
    )
  end
end
```

### In Models
```ruby
def split(split_quantity, logger: nil)
  ActiveRecord::Base.transaction do
    self.lock!  # Acquire pessimistic lock
    
    # Perform operation
    new_cq = self.class.create!(...)
    update!(quantity: split_quantity)
    
    # Log the transaction
    logger&.log_certificate_split(self, new_cq, split_quantity)
  end
rescue => e
  logger&.log_error(...)
  raise
end
```

## Benefits

1. **Complete Audit Trail**: Every action is logged with full context
2. **Data Integrity**: Pessimistic locking prevents race conditions
3. **Error Recovery**: Failed operations are logged for debugging
4. **State Reconstruction**: Can rebuild system state from log
5. **Compliance**: Immutable audit log for regulatory requirements
6. **Performance**: Indexed efficiently for fast queries

## Monitoring & Debugging

### Query Recent Transactions
```ruby
# View recent failures
Transaction.failed.recent.limit(10)

# Track specific certificate history
Transaction.for_certificate(cert_id).recent

# Monitor organization activity
Transaction.for_organization(org_id).by_event_type('certificate_retired')
```

### Request Tracing
All transactions include `request_id` for end-to-end tracing of API calls.

## Security Considerations

1. **Append-only design**: Prevents tampering with historical records
2. **User attribution**: All actions linked to authenticated users
3. **IP tracking**: Records source IP for security auditing
4. **Error sanitization**: Sensitive data excluded from error logs