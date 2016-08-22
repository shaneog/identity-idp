require 'rails_helper'

describe EventDecorator do
  describe '#pretty_event_type' do
    it 'converts all events types to strings' do
      Event.event_types.keys.each do |event_type|
        event = build_stubbed(:event, event_type: event_type)

        expect(event.decorate.pretty_event_type).to be_a(String)
      end
    end
  end
end
