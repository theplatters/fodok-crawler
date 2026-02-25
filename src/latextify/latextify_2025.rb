# frozen_string_literal: true

require_relative 'publications'
require_relative 'activities'
require_relative 'press'

def main
  parse_publications
  parse_activities
  parse_press
end

main
