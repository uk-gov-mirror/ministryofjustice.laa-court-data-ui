# frozen_string_literal: true

RSpec.describe ProsecutionCaseDecorator, type: :decorator do
  subject(:decorator) { described_class.new(prosecution_case, view_object) }

  let(:prosecution_case) { instance_double(CourtDataAdaptor::Resource::ProsecutionCase) }
  let(:view_object) { view_class.new }

  let(:view_class) do
    Class.new do
      include ActionView::Helpers
      include ApplicationHelper
    end
  end

  it_behaves_like 'a base decorator' do
    let(:object) { prosecution_case }
  end

  context 'when method is missing' do
    before { allow(prosecution_case).to receive_messages(hearings: nil) }

    it { is_expected.to respond_to(:hearings) }
  end

  describe '#hearings' do
    subject(:call) { decorator.hearings }

    before { allow(prosecution_case).to receive_messages(hearings: hearings) }

    context 'with multiple hearings' do
      let(:hearings) { [hearing1, hearing2] }
      let(:hearing1) { CourtDataAdaptor::Resource::Hearing.new }
      let(:hearing2) { CourtDataAdaptor::Resource::Hearing.new }

      it { is_expected.to all(be_instance_of(HearingDecorator)) }
    end

    context 'with no hearings' do
      let(:hearings) { [] }

      it { is_expected.to be_empty }
    end
  end

  describe '#cracked?' do
    subject(:call) { decorator.cracked? }

    before { allow(prosecution_case).to receive_messages(hearings: hearings) }

    context 'with no hearings' do
      let(:hearings) { [] }

      it { is_expected.to be_falsey }
    end

    context 'with a hearing without a "cracked" cracked_ineffective_trial object' do
      let(:hearings) { [hearing] }
      let(:hearing) { CourtDataAdaptor::Resource::Hearing.new }
      let(:cracked_ineffective_trial) do
        CourtDataAdaptor::Resource::CrackedIneffectiveTrial.new(type: 'Ineffective')
      end

      it { is_expected.to be_falsey }
    end

    context 'with a hearing with a "cracked" cracked_ineffective_trial object' do
      let(:hearings) { [hearing] }
      let(:hearing) { CourtDataAdaptor::Resource::Hearing.new }
      let(:cracked_ineffective_trial) do
        CourtDataAdaptor::Resource::CrackedIneffectiveTrial.new(type: 'Cracked')
      end

      before do
        allow(hearing).to receive(:cracked_ineffective_trial).and_return(cracked_ineffective_trial)
      end

      it { is_expected.to be_truthy }
    end

    context 'with multiple hearings with one "cracked" cracked_ineffective_trial object' do
      let(:hearings) { [hearing1, hearing2] }
      let(:hearing1) { CourtDataAdaptor::Resource::Hearing.new }
      let(:hearing2) { CourtDataAdaptor::Resource::Hearing.new }
      let(:cracked_ineffective_trial1) do
        CourtDataAdaptor::Resource::CrackedIneffectiveTrial.new(type: 'Vacated', code: 'A')
      end
      let(:cracked_ineffective_trial2) do
        CourtDataAdaptor::Resource::CrackedIneffectiveTrial.new(type: 'Ineffective', code: 'M1')
      end

      before do
        allow(hearing1).to receive(:cracked_ineffective_trial).and_return(cracked_ineffective_trial1)
        allow(hearing2).to receive(:cracked_ineffective_trial).and_return(cracked_ineffective_trial2)
      end

      it { is_expected.to be_truthy }
    end
  end
end
