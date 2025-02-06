require 'csv'

def generate_latex_for_publications(file, filename)
  latex = file.group_by { |i| i['year'] }.map do |year, by_year|
    "\\subsection*{#{year}}\n\\begin{enumerate}
    #{by_year.map do |row|
        "\t \\item #{row['authors']}: #{row['title']}#{row['citation']}"
      end.join("\n")}\n\\end{enumerate}\n"
  end.join
  File.write(filename, latex)
end

def get_year(date)
  date.split('.')[2].to_i
end

def generate_latex_for_scs(file, filename)
  by_year = file.group_by { |i| get_year(i['start']) }
  latex = ''
  by_year.each do |year, scs_by_year|
    latex += "\\subsection*{#{year}} \n"
    scs_by_year.group_by { |i| i['type'] }.each do |type, scs_by_type|
      latex += "\\paragraph{#{type}} \n"
      latex += "\\begin{enumerate}[leftmargin=*, labelsep=0.5cm] \n "
      scs_by_type.each do |e|
        start_end = if e['start'] == e['end']
                      e['start']
                    else
                      "#{e['start']} - #{e['end']}"
                    end
        latex += if e['place'].nil?
                   "\t \\item #{e['person']}: #{e['name']}. #{start_end} \n"
                 else
                   "\t \\item #{e['person']}: #{e['name']}. #{e['place']}, #{start_end} \n"
                 end
      end
      latex += "\\end{enumerate} \n"
    end
  end
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
    "\\paragraph{#{type}}\n\\begin{enumerate}#{
      by_type.map do |e|
        "\n\t\\item #{e['person']}: #{e['title']}#{institution(e)}#{e['citation']}"
      end.join}
\\end{enumerate}\n"
  end.join
end

def generate_latex_for_talks(file, filename)
  latex = file.group_by { |i| get_year(i['date']) }.map do |year, by_year|
    "\\subsection*{#{year}}\n
    #{generate_talk_type(by_year)}"
  end.join
  File.write(filename, latex)
end
working_papers, finished_papers = CSV.read('data/publications.csv', headers: true)
                                     .sort_by { |row| [row['year'].to_i, row['authors']] }
                                     .reverse
                                     .partition { |row| row['type'] == 'Working Paper' }

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
  row['invited-by'] == 'Research Seminar, ICAE' or row['invited-by'] == 'Open Research Seminar, ICAE'
end

generate_latex_for_talks(talks, 'data/talks.tex')
generate_latex_for_talks(research_seminar, 'data/research_seminar.tex')
