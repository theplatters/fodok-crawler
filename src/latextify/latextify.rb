require 'csv'

def generate_latex_for_publications(file, filename)
  latex = "\\begin{enumerate}[leftmargin=*, labelsep=0.5cm]\n"
  year = 0
  file.each do |row|
    if row['year'] != year
      year = row['year']
      latex += "\\end{enumerate} \n \\subsection*{#{year}} \n \\begin{enumerate}[leftmargin=*, labelsep=0.5cm] \n"
    end
    latex += "\t \\item #{row['authors']}:  #{row['title']}  #{row['citation']}\n"
  end
  latex += '\\end{enumerate}'
  File.write(filename, latex)
end

def get_year(date)
  date.split('.')[2].to_i
end

def generate_latex_for_scs(file, filename)
  by_year = file.group_by { |i| get_year(i['start']) }
  latex = ''
  by_year.each do |year, scs_by_year|
    latex += "\\subsection{#{year}} \n"
    scs_by_year.group_by { |i| i['type'] }.each do |type, scs_by_type|
      puts type
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
    end
  end
  File.write(filename, latex)
end

working_papers, finished_papers = CSV.read('data/publications.csv', headers: true)
                                     .sort_by { |row| [row['year'].to_i, row['authors']] }
                                     .reverse
                                     .partition { |row| row['type'] == 'Working Paper' }

_, finished_papers = finished_papers.partition { |row| row['type'] == 'Presseartikel / Medienberichte' }

generate_latex_for_publications(working_papers, 'data/working_papers.tex')
puts 'LaTeX itemize list generated in working_papers.tex'
generate_latex_for_publications(finished_papers, 'data/publications.tex')
puts 'LaTeX itemize list generated in publications.tex'

scs = CSV.read('data/scs.csv', headers: true)
         .sort_by { |row| [get_year(row['start']), row['person']] }
         .reverse

generate_latex_for_scs(scs, 'data/scs.tex')
puts 'LaTeX itemize list generated in scs.tex'
