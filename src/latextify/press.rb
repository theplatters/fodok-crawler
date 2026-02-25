require 'csv'
require_relative 'helper_methods'

def build_item_content(item)
  prelude = if item['Rollen der Mitwirkenden'] == 'Autor*in'
              "#{item['Personen']},"
            else
              "#{item['Personen']} zitiert in"
            end

  "#{prelude} #{item['Titel']}, #{item['Name']} #{item['Produzent/Autor']}#{item['Name Medienhaus/Outlet']} #{Date.parse(item['Datum der Veröffentlichung'])}"
end

def latextify_press(year, press_articles)
  subsection = "\\subsection*{#{year}}"
  items = press_articles.map do |item|
    "\t \\item #{build_item_content(item)}"
  end.join("\n")

  subsection + "
  \\begin{enumerate}
  #{items}
  \\end{enumerate}\n"
end

def generate_latex_for_press(press, out_filename)
  press['Jahr'] = press.map { |e| Date.parse(e['Datum der Veröffentlichung']).year }
  latex = group_by_year(press, &method(:latextify_press))
  File.write(out_filename, latex)
end

def generate_latex_for_media(press, out_file)
end

PRESS_FORMAT = %w[Hybrid Print Web NN].freeze

def parse_press
  all_media = CSV.read('data/presse.csv', headers: true)

  press = CSV::Table.new(
    all_media.select { |r| PRESS_FORMAT.include? r['Medienformat'] },
    headers: all_media.headers
  )

  radio = CSV::Table.new(
    all_media.reject { |r| PRESS_FORMAT.include? r['Medienformat'] },
    headers: all_media.headers
  )

  generate_latex_for_press(press, 'data/press.tex')
  generate_latex_for_media(radio, 'data/press.tex')
end
