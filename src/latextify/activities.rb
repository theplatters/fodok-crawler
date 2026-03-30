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
  held_at = !act.first['Veranstaltung'].to_s.empty? || act.first['Veranstaltung'] == act.first['Titel'] ? "gehalten bei #{act.first['Veranstaltung']}" : "gehalten bei #{act.first['Externe Organisation']}"

  cont = [
    build_persons(act),
    title[0],
    held_at,
    Date.parse(act.first['Startdatum']).strftime('%d.%m.%Y')
  ].reject(&:empty?).join(' ')

  "\t\\item #{sanitize(cont)}"
end

def build_item_for_rs(title, act)
  cont = [
    build_persons(act),
    title[0],
    Date.parse(act.first['Startdatum']).strftime('%d.%m.%Y')
  ].reject(&:empty?).join(' ')

  "\t\\item #{sanitize(cont)}"
end

def build_item_for_scs(title, act)
  cont = [
    build_persons(act),
    title[0],
    act.first['Veranstaltung'],
    Date.parse(act.first['Startdatum']).strftime('%d.%m.%Y')
  ].join(' ')

  "\t\\item #{sanitize(cont)}"
end

def build_item_for_scs_no_title(title, act)
  cont = [
    build_persons(act),
    title[0],
    Date.parse(act.first['Startdatum']).strftime('%d.%m.%Y')
  ].join(' ')

  "\t\\item #{sanitize(cont)}"
end

def by_title_date(row)
  [row['Titel'], row['Startdatum']]
end

def research_seminar_predicate(row)
  !(row['Veranstaltung'].to_s.include? 'Research' and row['Veranstaltung'].to_s.include? 'ICAE')
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

def scs_latextify
  group_formatter(
    group_by: ->(row) { row['Übergeordneter Typ'] }
  ) do |section_title, grouped_rows|
    content = group_by_year do |year, year_rows|
      items = group_formatter(group_by: method(:by_title_date)) do |title, act|
        if section_title == 'Organisation von Veranstaltung'

          build_item_for_scs(title, act)

        else

          build_item_for_scs_no_title(title, act)
        end
      end.call(year_rows)

      <<~LATEX
        \\subsection*{#{year}}
        \\begin{enumerate}
        #{items}
        \\end{enumerate}
      LATEX
    end.call(grouped_rows)

    <<~LATEX
      \\subsubsection{#{section_title}}
      #{content}
    LATEX
  end
end

def add_year(rows)
  rows.each do |row|
    row['Jahr'] = Date.parse(row['Startdatum']).year
  end
end

def by_year_rs
  by_year_formatter(
    &simple_formatter(
      group_by: method(:by_title_date),
      &method(:build_item_for_rs)
    )
  )
end

def by_year_act
  by_year_formatter(
    &simple_formatter(
      group_by: method(:by_title_date),
      &method(:build_item_for_activities)
    )
  )
end

def clean_up_activities_data(activities)
  activities.delete_if do |row|
    row['Übergeordneter Typ'] != 'Vortrag oder Präsentation'
  end

  activities['Titel'] = activities['Titel'].map do |titel|
    titel.gsub(/(Externe Organisation)/, '')
  end

  clean_up_names(activities)

  add_year(activities)

  activities.delete_if do |r|
    in_2026?(r)
  end
end

def parse_activities
  activities = CSV.read('data/aktivitaeten_erweitert.csv', headers: true)

  clean_up_activities_data(activities)

  finished, rs = activities.partition { |row| research_seminar_predicate(row) }

  generate_latex(finished, 'data/activities.tex', formatter: by_year_act)
  generate_latex(rs, 'data/rs.tex', formatter: by_year_rs)
end

def clean_scs_data(scs)
  add_year(scs)

  scs['Titel'] = scs['Titel'].map do |titel|
    titel.gsub('(Externe Organisation)', '')
  end

  scs.delete_if do |row|
    row['Übergeordneter Typ'] == 'Teilnehmer*in'
  end

  scs.delete_if do |r|
    in_2026?(r)
  end

  clean_up_names(scs)

  scs['Übergeordneter Typ'] = scs['Übergeordneter Typ'].map do |el|
    el.to_s == 'Teilnahme an oder Organisation einer Veranstaltung' ? 'Organisation einer Veranstaltung' : el.to_s
  end

  scs['Titel'] = scs['Titel'].map do |el|
    el.gsub('(Fachzeitschrift oder Schriftenreihe)', '').rstrip
  end
end

def parse_scs
  scs = CSV.read('data/aktivitaeten_erweitert.csv', headers: true).delete_if do |row|
    !TO_EXCLUDE.include? row ['Übergeordneter Typ']
  end
  clean_scs_data(scs)

  generate_latex(scs, 'data/scs.tex', formatter: scs_latextify, group_by_year: false)
end
