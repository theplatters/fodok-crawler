# frozen_string_literal: true

require 'csv'
require_relative 'helper_methods'

def build_item_content_for_press(item)
  prelude = if item['Rollen der Mitwirkenden'] == 'Autor*in'
              "#{item['Personen']}:"
            else
              "#{item['Personen']} zitiert in"
            end

  "#{prelude} #{item['Titel']}, #{item['Name']} #{item['Produzent/Autor']} #{item['Name Medienhaus/Outlet']} #{Date.parse(item['Datum der Veröffentlichung']).strftime('%d.%m.%Y')}"
end

def latextify_press(year, press_articles)
  subsection = "\\subsection*{#{year}}"
  items = press_articles.map do |item|
    "\t \\item #{build_item_content_for_press(item)}"
  end.join("\n")

  subsection + "
  \\begin{enumerate}
  #{items}
  \\end{enumerate}\n"
end

def generate_latex_for_press(press, out_filename)
  latex = group_by_year(press, &method(:latextify_press))
  File.write(out_filename, latex)
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
  generate_latex_for_press(press, 'data/press.tex')
  generate_latex_for_press(radio, 'data/radio.tex')
end
