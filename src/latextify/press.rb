# frozen_string_literal: true

require 'csv'
require_relative 'helper_methods'

def build_press_item(item)
  prelude = press_prelude(item)
  content = press_content(item)

  "\t \\item #{[prelude, content].reject(&:empty?).join(' ')}"
end

def press_prelude(item)
  if item[Columns::ROLE] == 'Autor*in'
    "#{item[Columns::PERSONS]}:"
  else
    "#{item[Columns::PERSONS]} zitiert in"
  end
end

def press_content(item)
  [
    item[Columns::TITLE],
    item[Columns::NAME],
    item[Columns::PRODUCER],
    item[Columns::MEDIA_HOUSE],
    formatted_press_date(item)
  ].map(&:to_s)
   .reject(&:empty?)
   .join(', ')
end

def formatted_press_date(item)
  Date.parse(item[Columns::PUBLICATION_DATE])
      .strftime('%d.%m.%Y')
end

def press_year_formatter
  by_year_formatter(
    &simple_formatter(&method(:build_press_item))
  )
end

PRESS_FORMAT = %w[Hybrid Print Web NN].freeze

def press_format?(row)
  PRESS_FORMAT.include?(row[Columns::MEDIA_FORMAT])
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
  clean_up_names(all_media, columns: [Columns::PERSONS])

  all_media[Columns::YEAR] = all_media.map { |e| Date.parse(e[Columns::PUBLICATION_DATE]).year }
  all_media[Columns::PRODUCER] = all_media[Columns::PRODUCER].map do |r|
    r.to_s.rstrip
  end

  all_media.delete_if do |r|
    in_2026?(r)
  end
end

def parse_press
  process_latex_pipeline(
    'data/presse.csv',
    clean: method(:clean_up_data),
    split: method(:split_press_and_radio),
    generate: lambda { |(press, radio)|
      generate_latex(press, 'data/press.tex', formatter: press_year_formatter)
      generate_latex(radio, 'data/radio.tex', formatter: press_year_formatter)
    }
  )
end
