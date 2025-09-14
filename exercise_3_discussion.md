# Exercise 3 Implementation

## Assumptions
1. A stale transfer is considered any transfer that is still status: `intransit` for > 24 hours. 
2. The number of stale transfers in a given day is < 1M
3. There is not a particular time of day we want to cancel `intransit` stale transfers en masse, we want to cancel ASAP after 24 hours of time in transit. 
4. There are not going to be model level validations added to the currently sparse validations on `CertificateQuantity` that would cause an automated update to fail.

## Discussion

I added a new column `certificate_quantities.transfer_initiated_at`. If exercise 1 were implemented, 
this might be a simpler column name like `status_updated_at` but for this exercise I figured let's be precise. 
This column must be updated when a transfer is initiated, accepted, or cancelled. 

We're kicking off a recurring SolidQueue job `CancelStaleTransfersJob` every 5 minutes to catch any `CertificateQuantities` in transit that have 
gone stale in the past 5 minutes. We've limited the concurrency to 1 so even if this job runs long, it shouldn't overlap
with another recurring job run. It will allow another job to run if one job is stuck for > 1 hr. 

## Extensions

### We want this to cancel intransit transfers immediately at our 24h threshold
We could enqueue a job to cancel the transfer at 24h exactly after the transfer was initiated, and if the CertificateQuantity is no longer `intransit`, the job is a noop. 

### We have millions of rows of transfers to cancel and this is always taking > 5 min
I would first try implementing a fanout strategy, where the periodic job `FindStaleTransfersJob` enqueues n other jobs `CancelStaleTransferJob`. `CancelStaleTransferJob` would take an argument for a `certificate_quantity_id`. Each `CancelStaleTransferJob` job would be responsible for 
canceling that stale transfer. If the state has changed and the certificate_quantity is no longer `intransit`, it would noop and return early. 
We would enqueue the jobs using bulk enqueuing to reduce roundtrips to the database: https://guides.rubyonrails.org/active_job_basics.html#bulk-enqueuing
