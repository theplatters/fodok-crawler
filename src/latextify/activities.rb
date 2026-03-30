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

def build_persons(act)
  extern_person = act.map { _1[Columns::EXTERNAL_PERSON] }.join(' ').strip
  persons = act.map { _1[Columns::PERSONS] }.join(' ').strip

  "#{persons}#{extern_person.empty? ? '' : " #{extern_person}"}:"
end

def held_at(act)
  if !act.first['Veranstaltung'].to_s.empty? || act.first['Veranstaltung'] == act.first[Columns::TITLE]
    "gehalten bei #{act.first['Veranstaltung']}"
  else
    "gehalten bei #{act.first['Externe Organisation']}"
  end
end

def build_item_for_activities(title, act)
  cont = [
    build_persons(act),
    title[0],
    held_at(act),
    format_date(act.first[Columns::START_DATE])
  ].reject(&:empty?).join(' ')

  "\t\\item #{sanitize(cont)}"
end

def build_item_for_rs(title, act)
  cont = [
    build_persons(act),
    title[0],
    format_date(act.first[Columns::START_DATE])
  ].reject(&:empty?).join(' ')

  "\t\\item #{sanitize(cont)}"
end

# Merged build_item_for_scs and build_item_for_scs_no_title
def build_scs_item(title, act, include_event: false)
  parts = [
    build_persons(act),
    title[0]
  ]

  parts << act.first['Veranstaltung'] if include_event

  parts << format_date(act.first[Columns::START_DATE])

  "\t\\item #{sanitize(parts.compact.join(' '))}"
end

def by_title_date(row)
  [row[Columns::TITLE], row[Columns::START_DATE]]
end

def research_seminar_predicate(row)
  !(row['Veranstaltung'].to_s.include? 'Research' and row['Veranstaltung'].to_s.include? 'ICAE')
end

def choose_item_formatter(section_title)
  if section_title == 'Organisation von Veranstaltung'
    method(:build_scs_item, include_event: true)
  else
    method(:build_scs_item)
  end
end

def build_content_for_scs(section_title, grouped_rows)
  item_formatter = choose_item_formatter(section_title)
  formatter = by_year_formatter(
    &simple_formatter(
      group_by: method(:by_title_date),
      &item_formatter
    )
  )
  group_by_year(&formatter).call(grouped_rows)
end

def scs_latextify
  group_formatter(
    group_by: ->(row) { row[Columns::TYPE] }
  ) do |section_title, grouped_rows|
    <<~LATEX
      \\subsubsection{#{section_title}}
      #{build_content_for_scs(section_title, grouped_rows)}
    LATEX
  end
end

def add_year(rows)
  rows.each do |row|
    row[Columns::YEAR] = Date.parse(row[Columns::START_DATE]).year
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

def clean_up(data)
  data[Columns::TITLE] = data[Columns::TITLE].map do |titel|
    titel.gsub('(Externe Organisation)', '')
  end

  data.delete_if do |row|
    row[Columns::TYPE] == 'Teilnehmer*in'
  end

  clean_up_names(data)

  add_year(data)

  data.delete_if do |r|
    in_2026?(r)
  end
end

def clean_up_activities_data(activities)
  activities.delete_if do |row|
    row[Columns::TYPE] != 'Vortrag oder Präsentation'
  end
end

def clean_scs_data(scs)
  scs[Columns::TYPE] = scs[Columns::TYPE].map do |el|
    el.to_s == 'Teilnahme an oder Organisation einer Veranstaltung' ? 'Organisation einer Veranstaltung' : el.to_s
  end

  scs[Columns::TITLE] = scs[Columns::TITLE].map do |el|
    el.gsub('(Fachzeitschrift oder Schriftenreihe)', '').rstrip
  end
end

def parse_activities
  process_latex_pipeline(
    'data/aktivitaeten_erweitert.csv',
    clean: lambda { |data|
      clean_up(data)
      clean_up_activities_data(data)
      data # Ensure the cleaned data is returned
    },
    split: lambda { |data|
      data.partition { |row| research_seminar_predicate(row) }
    },
    generate: lambda { |(finished, rs)|
      generate_latex(finished, 'data/activities.tex', formatter: by_year_act)
      generate_latex(rs, 'data/rs.tex', formatter: by_year_rs)
    }
  )
end

def parse_scs
  process_latex_pipeline(
    'data/aktivitaeten_erweitert.csv',
    clean: lambda { |data|
      data.delete_if { |row| !TO_EXCLUDE.include?(row[Columns::TYPE]) }
      clean_up(data)
      clean_scs_data(data)
      data
    },
    generate: lambda { |scs_data|
      generate_latex(scs_data, 'data/scs.tex', formatter: scs_latextify, group_by_year: false)
    }
  )
end
