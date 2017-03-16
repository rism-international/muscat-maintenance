#!/bin/bash
cd ../../
#rails runner housekeeping/maintenance/export/sources_to_bsb.rb
rails runner housekeeping/maintenance/export/people_to_bsb.rb
rails runner housekeeping/maintenance/export/institutions_to_bsb.rb
rails runner housekeeping/maintenance/export/catalogues_to_bsb.rb
