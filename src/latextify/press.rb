# frozen_string_literal: true

require 'csv'
require_relative 'helper_methods'

def build_item_content_for_press(item); end

def build_press_item(item)
  prelude = press_prelude(item)
  content = press_content(item)

  "\t \\item #{[prelude, content].reject(&:empty?).join(' ')}"
end

def press_prelude(item)
  if item['Rollen der Mitwirkenden'] == 'Autor*in'
    "#{item['Personen']}:"
  else
    "#{item['Personen']} zitiert in"
  end
end

def press_content(item)
  [
    item['Titel'],
    item['Name'],
    item['Produzent/Autor'],
    item['Name Medienhaus/Outlet'],
    formatted_press_date(item)
  ].map(&:to_s)
   .reject(&:empty?)
   .join(', ')
end

def formatted_press_date(item)
  Date.parse(item['Datum der Veröffentlichung'])
      .strftime('%d.%m.%Y')
end

def press_year_formatter
  by_year_formatter(
    formatter: simple_formatter(&method(:build_press_item))
  )
end

PRESS_FORMAT = %w[Hybrid Print Web NN].freeze

def press_format?(row)
  PRESS_FORMAT.include?(row['Medienformat'])
end

def split_press_and_radio(all_media)
  press = CSV::Table.new(all_media.select do |r|
    press_format?(r)
  end, headers: all_media.headers)
  radio = CSV::Table.new(all_media.reject do |r|
    press_format?(r)
  end, headers: all_media.headers)
  [press, radio]
end

def clean_up_data(all_media)
  all_media['Personen'] = all_media['Personen'].map do |r|
    r.gsub(' //', ',')
  end
  all_media['Produzent/Autor'] = all_media['Produzent/Autor'].map do |r|
    r.to_s.rstrip
  end
  all_media
end

def parse_press
  all_media = CSV.read('data/presse.csv', headers: true)
  all_media['Jahr'] = all_media.map { |e| Date.parse(e['Datum der Veröffentlichung']).year }
  all_media = clean_up_data(all_media)
  press, radio = split_press_and_radio(all_media)
  generate_latex(press, 'data/press.tex', formatter: press_year_formatter)
  generate_latex(radio, 'data/radio.tex', formatter: press_year_formatter)
end
