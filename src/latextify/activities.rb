# frozen_string_literal: true

require 'csv'
require 'date'

require_relative 'helper_methods'

TO_EXCLUDE = ['Andere Gutachtertätigkeit',
              'Begutachtung von Publikationen und Herausgebertätigkeiten',
              'Begutachtung von Publikationen',
              'Begutachtung von Publikationen oder Herausgebertätigkeit (Altdaten)',
              'Gutachter/in für Förderinstitution',
              'Herausgebertätigkeit',
              'Organisation von Konferenz, Workshop, ...',
              'Programm-Komitee',
              'Sonstige Mitgliedschaft/Funktion',
              'Teilnahme an Konferenz, Workshop, ...',
              'Teilnahme an oder Organisation einer Veranstaltung',
              'Mitgliedschaft/Funktion',
              'Gutachtertätigkeit',
              'Gutachtertätigkeiten',
              'Wissenschaftliche Gesellschaft'].freeze

def sort_by_organisator_then_alphabetically(acts)
  acts.sort do |a, b|
    next 1 if a['Rollen der Mitwirkenden'] == 'Moderator*in' && b['Rollen der Mitwirkenden'] != 'Moderator*in'
    next 1 if a['Rollen der Mitwirkenden'] == 'Vortragende*r' && b['Rollen der Mitwirkenden'] != 'Vortragende*r'

    a['Personen'].to_s <=> b['Personen'].to_s
  end
  acts
end

def build_persons(act)
  extern_person = act.map { _1['Externe Person'] }.join(' ').strip
  persons = act.map { _1['Personen'] }.join(' ').strip

  "#{persons}#{extern_person.empty? ? '' : " #{extern_person}"}:"
end

def build_item_for_activities(title, act)
  cont = [
    build_persons(act),
    title[0],
    act.first['Title'],
    Date.parse(act.first['Startdatum']).strftime('%d.%m.%Y')
  ].join(' ')

  "\t\\item #{sanitize(cont)}"
end

def by_title_date(row)
  [row['Titel'], row['Startdatum']]
end

def research_seminar_predicate(row)
  !(row['Title'].to_s.include? 'Research' and row['Title'].to_s.include? 'ICAE')
end

def build_subsection(_type, activities)
  items = activities.group_by { |r| by_title_date(r) }.map do |title, act|
    build_item_for_activities(title, act)
  end.join("\n")
  "\\begin{enumerate}
#{items}
\\end{enumerate}
"
end

def activities_latextify(year, rows)
  subsection = "\\subsection*{#{year}}\n"

  subsection + rows.group_by { _1['Übergeordneter Typ'] }
                   .map { |k, v| build_subsection(k, v) }
                   .join
end

def generate_latex_for_activities(rows, out_filename, formatter: method(:activities_latextify))
  rows.each do |row|
    row['Jahr'] = Date.parse(row['Startdatum']).year
  end
  latex = group_by_year(rows, &formatter)

  File.write(out_filename, latex)
end

def scs_latextify(year, rows)
  items = rows.group_by { |r| r['Übergeordneter Typ'] }.map do |title, grouped_rows|
    cont = grouped_rows.group_by do |r|
      by_title_date(r)
    end.map { |title, act| build_item_for_activities(title, act) }.join("\n")
    "\\subsubsection{#{title}}" + "
\\begin{enumerate}
#{cont}
\\end{enumerate}"
  end.join("\n")
  "\\subsection*{#{year}}
  #{items}"
end

def rs_latextify(year, rows)
  subsection = "\\subsection*{#{year}}"

  items = rows.group_by { |r| by_title_date(r) }.map { |title, act| build_item_for_activities(title, act) }.join("\n")
  subsection + "
\\begin{enumerate}
#{items}
\\end{enumerate}
"
end

def parse_activities
  activities = CSV.read('data/aktivitaeten_erweitert.csv', headers: true)

  finished_arr, rs_arr = activities.partition { |row| research_seminar_predicate(row) }

  finished = CSV::Table.new(finished_arr, headers: activities.headers)
  rs       = CSV::Table.new(rs_arr,       headers: activities.headers)
  finished = finished.select { |row| row['Übergeordneter Typ'] == 'Vortrag oder Präsentation' }

  generate_latex_for_activities(finished, 'data/activities.tex')
  generate_latex_for_activities(rs, 'data/rs.tex', formatter: method(:rs_latextify))
end

def parse_scs
  scs = CSV.read('data/aktivitaeten_erweitert.csv', headers: true).delete_if do |row|
    !TO_EXCLUDE.include? row ['Übergeordneter Typ']
  end

  scs.delete_if do |row|
    row['Übergeordneter Typ'] == 'Teilnehmer*in'
  end

  scs['Übergeordneter Typ'] = scs['Übergeordneter Typ'].map do |el|
    el.to_s == 'Teilnahme an oder Organisation einer Veranstaltung' ? 'Organisation einer Veranstaltung' : el.to_s
  end

  generate_latex_for_activities(scs, 'data/scs.tex', formatter: method(:scs_latextify))
end
