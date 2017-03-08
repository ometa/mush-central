require 'spec_helper'
require 'stripe_mock'

describe CompletedRequirement do

  let(:stripe_helper) { StripeMock.create_test_helper }

  describe '#metadata' do
    let (:hash) {{ 'foo' => 'bar' }}
    let (:cr) { FactoryGirl.create :completed_requirement }

    it 'returns a hash of JSON data' do
      cr.metadata = JSON.generate hash
      expect(cr.metadata).to eq(hash)
    end

    it 'returns hash of hash data' do
      cr.metadata = hash
      expect(cr.metadata).to eq(hash)
    end

    it 'returns nil if metadata is nil' do
      cr.metadata = nil
      expect(cr.metadata).to be_nil
    end
  end

  describe 'validation' do
    describe 'fails' do
      let (:rr) { FactoryGirl.create :completed_requirement }
      it 'when team/requirement pair exists (with same user)' do
        expect(FactoryGirl.build :cr, :team => rr.team,
               :requirement => rr.requirement, :user => rr.user)
        .to be_invalid
      end

      it 'when team/requirement pair exists (with different user)' do
        expect(FactoryGirl.build :cr, :team => rr.team,
               :requirement => rr.requirement, :user => FactoryGirl.create(:user2))
        .to be_invalid
      end
    end
  end

  describe '#delete_by_charge' do

    let(:cr)   { FactoryGirl.create :completed_requirement }
    let(:req)  { cr.requirement }
    let(:team) { cr.team }

    let(:customer) do
      Stripe::Customer.create({
        card: stripe_helper.generate_card_token,
        email: team.user.email,
        metadata: {
        user_id: team.user.id
      }
      })
    end

    let(:charge) do
      Stripe::Charge.create({
        customer:    customer.id,
        amount:      7000,
        currency:    'usd',
        description: 'Registration Fee for Arizona Quints | Chiditarod X',
        metadata: {
          race_name: team.race.name,
          team_name: team.name,
          requirement_id: req.id,
          team_id: team.id
        }
      })
    end

    before { StripeMock.start }
    after  { StripeMock.stop  }

    context 'when the completed requirement is found' do
      it 'is destroyed' do
        expect(CompletedRequirement).to receive(:destroy).with(cr)
        CompletedRequirement.delete_by_charge(charge)
      end
    end

    context 'when the completed requirement is not found' do

      let(:charge) do
        Stripe::Charge.create({
          customer:    customer.id,
          amount:      7000,
          currency:    'usd',
          description: 'Registration Fee for Arizona Quints | Chiditarod X',
          metadata: {
            race_name: team.race.name,
            team_name: team.name,
            requirement_id: (cr.requirement_id + 1),
            team_id: team.id
          }
        })
      end

      it 'is not destroyed' do
        expect(CompletedRequirement).to_not receive(:destroy).with(cr)
        CompletedRequirement.delete_by_charge(charge)
      end
    end
  end
end
