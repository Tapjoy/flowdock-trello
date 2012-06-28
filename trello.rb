require 'rubygems'
require 'faraday'
require 'json'
require 'time'

trello_board = ENV['TRELLO_BOARD']
trello_key = ENV['TRELLO_KEY']
trello_token = ENV['TRELLO_TOKEN']
flowdock_token = ENV['FLOWDOCK_TOKEN']
flowdock_email = ENV['FLOWDOCK_EMAIL']

def text_to_html(text)
  start_tag = '<p>'
  text = text.to_str
  text.gsub!(%r/\r\n?/, "\n")
  text.gsub!(%r/\n\n+/, "</p>\n\n#{start_tag}")
  text.gsub!(%r/([^\n]\n)(?=[^\n])/, '\1<br />')
  text.insert 0, start_tag
  text << '</p>'
end

trello = Faraday.new(:url => 'https://api.trello.com') do |faraday|
  faraday.request :url_encoded
  faraday.adapter Faraday.default_adapter
end

flowdock = Faraday.new(:url => 'https://api.flowdock.com') do |faraday|
  faraday.request :url_encoded
  faraday.adapter Faraday.default_adapter
end

last_time = nil

while true
  sleep 60
  
  begin
    response = trello.get "/1/boards/#{trello_board}/actions?key=#{trello_key}&token=#{trello_token}"
    results = JSON.parse(response.body)
    results.reverse!
    
    if last_time
      results.each do |result|
        begin
          next if Time.parse(result['date']) <= last_time
          puts result.inspect
          
          data = result['data']
          source = 'Trello'
          from = result['memberCreator']['fullName']
          from_address = flowdock_email
          project = data['board']['name']
          board_link = "https://trello.com/board/#{data['board']['id']}"
          card_link = "https://trello.com/card/#{data['board']['id']}/#{data['card']['idShort']}"
          card_name = data['card']['name']
          case result['type']
          when 'addMemberToCard'
            subject = "Added #{result['member']['fullName']} to: #{card_name}"
            content = card_name
          when 'commentCard'
            subject = "Commented on: #{card_name}"
            content = data['text']
          when 'createCard'
            subject = "Created: #{card_name}"
            content = card_name
          when 'removeMemberFromCard'
            subject = "Removed #{result['member']['fullName']} from: #{card_name}"
            content = card_name
          when 'updateCard'
            if data['listAfter'] && data['listBefore']['name'] != data['listAfter']['name']
              subject = "Moved to #{data['listAfter']['name']}: #{card_name}"
            elsif data['old'] && data['old']['desc']
              subject = "Updated description for: #{card_name}"
            elsif data['old'] && data['old']['name']
              subject = "Updated name for: #{card_name}"
            elsif data['old'] && !data['old']['closed'].nil?
              if data['old']['closed']
                subject = "Reopened: #{card_name}"
              else
                subject = "Archived: #{card_name}"
              end
            else
              next
            end
            content = data['card']['desc'] || 'Updated'
          when 'updateCheckItemStateOnCard'
            subject = "Updated #{data['checkItem']['name']} on: #{card_name}"
            content = "State: #{data['checkItem']['state'] || 'incomplete'}"
          else
            next
          end
          content = text_to_html(content)
          
          flowdock.post "/v1/messages/team_inbox/#{flowdock_token}", {
            :source => source,
            :from_address => from_address,
            :subject => subject,
            :content => content,
            :from_name => from,
            :project => project,
            :format => 'html',
            :link => card_link
          }
        rescue Exception => ex
          puts ex.message
          puts ex.backtrace * "\n"
        end
      end
    end
    
    # Set last time of most recent result
    results.each do |result|
      timestamp = Time.parse(result['date'])
      last_time = last_time ? [last_time, timestamp].max : timestamp
    end
  rescue Exception => ex
    puts ex.message
    puts ex.backtrace * "\n"
  end
end
