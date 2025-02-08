require 'csv'

def sanitize(string)
  string.gsub(/([&%$#_{}^\\])/, '\\\\\1').gsub('"', "''").gsub('-', '--')
end

def paragraph(str)
  "\\paragraph{#{sanitize(str)}}"
end

def generate_latex_for_publications(file, filename)
  latex = file.group_by { |i| i['year'] }.map do |year, by_year|
    "\\subsection*{#{year}}\n\\begin{enumerate}
    #{by_year.map do |row|
        s = sanitize("#{row['authors']}: #{row['title']}#{row['citation']}")
        "\t \\item #{s}"
      end.join("\n")}\n\\end{enumerate}\n"
  end.join
  File.write(filename, latex)
end

def get_year(date)
  date.split('.')[2].to_i
end

def generate_scs_type(scs)
  scs.map do |e|
    duration = e['start'] == e['end'] ? e['start'] : "#{e['start']} - #{e['end']}"
    location = [e['place'], duration].compact.join(', ')
    s = sanitize("#{e['person']}: #{e['name']}. #{location}")
    "\\item #{s}"
  end.join("\n")
end

def generate_latex_for_scs(file, filename)
  latex = file.group_by { |e| get_year(e['start']) }.map do |year, entries|
    "\\subsection*{#{year}}" +
      entries.group_by { |e| e['type'] }.map do |type, scs|
        "#{paragraph(type)}
\\begin{enumerate}[leftmargin=*, labelsep=0.5cm]
#{generate_scs_type(scs)}
\\end{enumerate}"
      end.join("\n")
  end.join
  File.write(filename, latex)
end

def institution(row)
  if row['place'].nil? && row['invited-by'].nil? && row['original-title'].nil?
    ''
  else
    institution_info = ". #{row['invited-by']}#{row['original-title']}"
    institution_info += ", #{row['place']}" unless row['place'].nil?
    institution_info
  end
end

def generate_talk_type(by_year)
  by_year.group_by { |i| i['type'] }.map do |type, by_type|
    "#{paragraph(type)}\n\\begin{enumerate}#{
      by_type.map do |e|
        s = sanitize("#{e['person']}: #{e['title']}#{institution(e)}#{e['citation']}")
        "\n\t\\item #{s}"
      end.join}
\\end{enumerate}\n"
  end.join
end

def generate_latex_for_talks(file, filename)
  latex = file.group_by { |i| get_year(i['date']) }.map do |year, by_year|
    "\\subsection*{#{year}}\n#{generate_talk_type(by_year)}"
  end.join
  File.write(filename, latex)
end
working_papers, finished_papers = CSV.read('data/publications.csv', headers: true)
                                     .sort_by { |row| [row['year'].to_i, row['authors']] }
                                     .reverse
                                     .partition do |row|
  row['type'] == 'Working Paper' && (row['citation'].include?('ICAE') || row['citation'].include?('SPACE'))
end

press_articles, finished_papers = finished_papers.partition { |row| row['type'] == 'Presseartikel / Medienberichte' }

generate_latex_for_publications(working_papers, 'data/working_papers.tex')
puts 'LaTeX itemize list generated in working_papers.tex'
generate_latex_for_publications(finished_papers, 'data/publications.tex')
puts 'LaTeX itemize list generated in publications.tex'
generate_latex_for_publications(press_articles, 'data/press_articles.tex')
puts 'LaTeX itemize list generated in press_articles.tex'

scs = CSV.read('data/scs.csv', headers: true)
         .sort_by { |row| [get_year(row['start']), row['person']] }
         .reverse

generate_latex_for_scs(scs, 'data/scs.tex')
puts 'LaTeX itemize list generated in scs.tex'

research_seminar, talks = CSV.read('data/talks.csv', headers: true)
                             .sort_by { |row| [get_year(row['date']), row['person']] }
                             .reverse
                             .partition do |row|
  (!row['invited-by'].nil? && row['invited-by'].include?('Research Seminar')) or
    (!row['original-title'].nil? && row['original-title'].include?('Research Seminar'))
end

media, talks = talks.partition { |row| row['type'] == 'Präsentation in Radio/TV' }

generate_latex_for_talks(talks, 'data/talks.tex')
generate_latex_for_talks(research_seminar, 'data/research_seminar.tex')
generate_latex_for_talks(media, 'data/media.tex')
