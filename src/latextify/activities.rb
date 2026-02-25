# frozen_string_literal: true

require 'csv'
require 'date'

require_relative 'helper_methods'

TO_EXCLUDE = ['Andere Gutachtertätigkeit',
              'Begutachtung von Publikationen',
              'Begutachtung von Publikationen oder Herausgebertätigkeit (Altdaten)',
              'Gutachter/in für Förderinstitution',
              'Herausgebertätigkeit',
              'Organisation von Konferenz, Workshop, ...',
              'Programm-Komitee',
              'Sonstige Mitgliedschaft/Funktion',
              'Teilnahme an Konferenz, Workshop, ...',
              'Wissenschaftliche Gesellschaft'].freeze

def build_item_for_activities(act)
  cont = "#{act['Personen']} #{act['Externe Personen']} #{act['Titel']} #{act['Title']} #{act['Startdatum']}"
  "\t\\item #{sanitize(cont)}"
end

def research_seminar_predicate(row)
  !(row['Title'].to_s.include? 'Research' and row['Title'].to_s.include? 'ICAE')
end

def build_subsection(type, activities)
  subsection = "\\subsection*{#{sanitize(type)}}\n"
  items = activities.map { build_item_for_activities(_1) }.join("\n")
  subsection + "
\\begin{enumerate}
#{items}
\\end{enumerate}
"
end

def activities_latextify(year, rows)
  subsection = "\\subsection*{#{year}}\n"

  subsection + rows.group_by { _1['Übergeordneter Typ'] }
                   .map { |k, v| build_subsection(k, v) }
                   .join('\n')
end

def generate_latex_for_activities(rows, out_filename)
  rows.each do |row|
    row['Jahr'] = Date.parse(row['Startdatum']).year
  end
  latex = group_by_year(rows, &method(:activities_latextify))

  File.write(out_filename, latex)
end

def parse_activities
  activities = CSV.read('data/aktivitaeten_erweitert.csv', headers: true)

  finished_arr, rs_arr = activities.partition { |row| research_seminar_predicate(row) }

  finished = CSV::Table.new(finished_arr, headers: activities.headers)
  rs       = CSV::Table.new(rs_arr,       headers: activities.headers)
  finished = finished.delete_if { |row| TO_EXCLUDE.include?(row['Übergeordneter Typ']) }

  generate_latex_for_activities(finished, 'data/activities.tex')
  generate_latex_for_activities(rs, 'data/rs.tex')
end
