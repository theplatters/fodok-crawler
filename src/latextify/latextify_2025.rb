# frozen_string_literal: true

require 'csv'

def sanitize(string)
  string&.gsub(/([&%$#_{}^\\])/, '\\\\\1')&.gsub(/"(.+)"/, '\\glqq \1\\grqq{}')&.gsub(/ - /, ' -- ')
end

def generate_latex_for_publications(rows, out_filename)
  latex = rows
          .group_by { |row| row['Jahr'] }
          .map do |year, publications|
    subsection = "\\subsection*{#{year}}\n"

    items = publications.map do |pub|
      "\t\\item #{sanitize(pub['APA-Format'])}"
    end.join("\n")

    subsection + "\\begin{enumerate}\n#{items}\n\\end{enumerate}\n"
  end.join
  File.write(out_filename, latex)
end

class CSV
  class Table
    def sort_by_year_apa
      sort_by do |row|
        [-row['Jahr'].to_i, row['APA-Format'].to_s]
      end
    end
  end
end

WP_SERIES = ['ICAE Working Paper Series', 'SPACE Working Paper Series'].freeze

def parse_publications
  publications = CSV.read('data/publikationen.csv', headers: true).sort_by_year_apa
  by_series = publications.group_by { |row| row['Serienname'] }

  generate_latex_for_publications(by_series['SPACE Working Paper Series'], 'data/space_wp.tex')
  generate_latex_for_publications(by_series['ICAE Working Paper Series'], 'data/icae_wp.tex')

  finished = by_series.reject { |series, _| WP_SERIES.include?(series) }.values.flatten(1)
  generate_latex_for_publications(finished, 'data/publications.tex')
end

TO_EXCLUDE = ['Andere Gutachtertätigkeit', 'Begutachtung von Publikationen',
              'Begutachtung von Publikationen oder Herausgebertätigkeit (Altdaten)', 'Gutachter/in für Förderinstitution', 'Herausgebertätigkeit', 'Organisation von Konferenz, Workshop, ...', 'Programm-Komitee', 'Sonstige Mitgliedschaft/Funktion', 'Teilnahme an Konferenz, Workshop, ...', 'Wissenschaftliche Gesellschaft'].freeze

def generate_latex_for_activities(rows, out_filename)
  latex = rows.map do |type, activities|
    subsection = "\\subsection*{#{sanitize(type)}}\n"

    items = activities.map do |act|
      cont = act['Personen'].to_s + ' ' +
             act['Externe Personen'].to_s + ' ' +
             act['Titel'].to_s + ' ' +
             act['Title'].to_s + ' ' +
             act['Startdatum'].to_s
      "\t\\item #{sanitize(cont)}"
    end.join("\n")

    subsection + "\\begin{enumerate}\n#{items}\n\\end{enumerate}\n"
  end.join

  File.write(out_filename, latex)
end

def parse_activities
  activities = CSV.read('data/aktivitaeten_erweitert.csv', headers: true).group_by { |e| e['Übergeordneter Typ'] }

  finished = activities.reject { |series, _| TO_EXCLUDE.include?(series) }
  generate_latex_for_activities(finished, 'data/activities.tex')
end

def main
  parse_publications
  parse_activities
end

main
