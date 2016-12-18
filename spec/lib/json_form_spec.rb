require 'spec_helper'

describe JsonForm do

  let(:race) { FactoryGirl.create :race_with_jsonform }
  let(:auth_token) { 'fake_token' }

  describe "add_csrf" do
    let(:result) { JsonForm.add_csrf(JSON.parse(race.jsonform), auth_token) }

    let(:expected_schema) {{
      "type" => "string",
      "default" => auth_token
    }}

    let(:expected_form) {{
      "type" => "hidden",
      "key" => 'authenticity_token'
    }}

    it 'sets the appropriate csrf data onto the jsonform' do
      expect(result['schema']['properties']['authenticity_token']).to eq(expected_schema)
      expect(result['form'].detect{|item| item['key'] == 'authenticity_token'}).to eq(expected_form)
    end
  end

  describe "#add_saved_answers" do

    let(:result)     { JsonForm.add_saved_answers(team, JSON.parse(race.jsonform), auth_token) }

    context 'team has saved answers already' do
      let(:team) { FactoryGirl.create :team_with_jsonform, race: race }

      it "merges the saved answers into the 'value' key and includes the authenticity_token" do
        auth_hash = { 'authenticity_token' => auth_token }
        expect(result['value']).to eq(JSON.parse(team.jsonform).merge(auth_hash))
      end
    end

    context 'team has no saved answers' do
      let(:team){ FactoryGirl.create :team, race: race }

      it "returns the exact same jsonform" do
        expect(result).to eq(JSON.parse(race.jsonform))
      end
    end
  end
end