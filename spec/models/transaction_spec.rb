require 'rails_helper'

describe Transaction, type: :model do
  context 'when composing the record' do
    let(:transaction) { create(:transaction, old_state: old_state, new_state: new_state) }
    subject { transaction }

    context 'when an old state and new state are supplied' do
      let(:old_state) { nil }
      let(:new_state) { nil }

      it 'updates the old state' do
        subject.set_states({old_state: '{:field=>"old_value"}', new_state: '{:field=>"new_value"}'})
        expect(subject.old_state).to eq('{:field=>"old_value"}')
      end
      it 'updates the new state' do
        subject.set_states({old_state: '{:field=>"old_value"}', new_state: '{:field=>"new_value"}'})
        expect(subject.new_state).to eq('{:field=>"new_value"}')
      end
    end
  end

  #  context 'when closing the record' do
  #   let(:transaction) { create(:transaction) }

  #   context 'when the record is unsaved' do
  #     subject { transaction }

  #     it 'can be closed successfully' do
  #       subject.save_as_success
  #       expect(subject.completed).to eq true
  #     end

  #     it 'can be closed with errors' do
  #       subject.save_as_error
  #       expect(subject.completed).to eq false
  #     end
  #   end
  # end
end
