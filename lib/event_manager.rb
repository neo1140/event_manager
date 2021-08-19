require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
puts 'EventManager Initialized!'

def clean_phone_numbers(number)
  number = (number.split('-')).join
  number = (number.split('.')).join
  number = (number.split(')')).join
  number = (number.split(' ')).join
  number = (number.split('(')).join
  if number.to_s.length == 10
    number
  elsif number.to_s.length == 11 && number.to_s[0] == '1'
    number = number.to_s.slice(1, 10)
  else
    number = '0000000000'
  end
end

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0').slice(0, 5)
end

def legilators_by_zipcode(zip)
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

def save_thank_you_letter(id,form_letter)
  Dir.mkdir('output') unless  Dir.exist?('output')
  filename = "output/thanks_#{id}.html"
  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end
def clean_time(time)
  time = Time.strptime(time, '%m/%d/%y %k:%M')
  time.strftime('%l:%M %p %A')
end

def time_counter(time, counter)
  time_array = time.split(' ')
  counter["#{time_array[0].split(':')[0]} #{time_array[1]}"] += 1
end

def day_counter(time, counter)
  time_array = time.split(' ')
  counter[time_array[2]] += 1
end

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
  )

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter
day_hash = Hash.new(0)
time_hash = Hash.new(0)

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  number = row[:homephone]
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legilators_by_zipcode(zipcode)
  form_letter = erb_template.result(binding)
  time = clean_time(row[:regdate])
  save_thank_you_letter(id, form_letter)
  time_counter(time, time_hash)
  day_counter(time, day_hash)
end
p day_hash
p time_hash
