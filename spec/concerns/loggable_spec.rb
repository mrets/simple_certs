require 'rails_helper'


describe Transaction do
  context 'when a generation is created'
  let(:generator) { create(:generator) }
  let(:generation) { create(:generation, quantity: 5, generator: generator) }
  initial_log_count = Transaction.count

  it 'adds a transaction to the log' do
    expect(Transaction.count).to eq(initial_log_count + 1)
  end

end