require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def clean_phone_number(number)
  clean_number = number.scan(/\d+/).join('')
  if clean_number.length == 10
    clean_number.insert(3, '-').insert(7, '-')
  elsif clean_number.length > 10 && clean_number[0] == '1'
    clean_number[1..10].insert(3, '-').insert(7, '-')
  else
    'N/A'
  end
end

def format_time(time)
  time = time.scan(/\d+/)
  Time.new("20#{time[2]}", time[0], time[1], time[3],time[4])
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'
  begin
    legislators = civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')
  filename = "output/thanks_#{id}.html"
  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts 'Event Manager Initialized!'

def open_content
  content = CSV.open(
    'event_attendees.csv',
    headers: true,
    header_converters: :symbol
  )
end

# template_letter = File.read('form_letter.erb')
# erb_template = ERB.new template_letter
def set_content
  contents = open_content
  contents.each do |row|
    id = row[0]
    date = format_time(row[:regdate])
    name = row[:first_name]
    phone_number = clean_phone_number(row[:homephone])
    zipcode = clean_zipcode(row[:zipcode])
    legislators = legislators_by_zipcode(zipcode)
    # puts "#{name}, #{phone_number} -------- #{date}"
    # form_letter = erb_template.result(binding)
    # save_thank_you_letter(id, form_letter)
  end
end

def popular_hour
  hours = Hash.new { |h, k| h[k] = 0 }
  contents = open_content
  contents.each do |row|
    date = format_time(row[:regdate])
    reg_hour = date.hour
    hours[:"#{reg_hour}"] += 1
  end
  most_popular_hour = hours.each { |k, v| puts "Hour #{k}: #{v} registrations." if v == hours.values.max}
end

def popular_day
  days = Hash.new { |h, k | h[k] = 0 }
  contents = open_content
  contents.each do |row|
    date = format_time(row[:regdate])
    reg_day = date.wday
    days[:"#{reg_day}"] += 1
  end
  most_popular_day = days.each { |k, v| puts "#{Date::DAYNAMES[k.to_s.to_i]}: #{v} registrations." if v == days.values.max}
end
