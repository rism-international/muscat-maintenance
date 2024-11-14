#!/bin/bash
cd ../../
rails r housekeeping/export/xml-export.rb -f /tmp/sources.xml -m Source -l
rails r housekeeping/export/xml-export.rb -f /tmp/people.xml -m Person -l
rails r housekeeping/export/xml-export.rb -f /tmp/institutions.xml -m Institution -l
rails r housekeeping/export/xml-export.rb -f /tmp/catalogues.xml -m Publication -l



#rails runner housekeeping/maintenance/export/sources_to_bsb.rb
#rails runner housekeeping/maintenance/export/people_to_bsb.rb
#rails runner housekeeping/maintenance/export/institutions_to_bsb.rb
#rails runner housekeeping/maintenance/export/catalogues_to_bsb.rb
#rails runner housekeeping/maintenance/export/works_to_bsb.rb
#rails runner housekeeping/maintenance/export/generate_beacon.rb
