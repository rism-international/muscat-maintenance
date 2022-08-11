CONF = { "Autograph manuscript" => { t: [1,2], a: nil,  b: "Notated music"},
"Possible autograph manuscript" => {t: [1,2], a: nil, b: "Notated music"},
"Partial autograph" => {t: [1,2], a: nil, b: "Notated music"},
"Manuscript copy" => {t: [1,2], a: nil, b: "Notated music"},
"Manuscript copy with autograph annotations" => {t: [1,2], a: nil, b: "Notated music"},
"Libretto, handwritten" => {t: [4], a: "Manuscript copy", b: "Libretto"},
"Treatise, handwritten" => {t: [6], a: "Manuscript copy", b: "Treatise"},
"Print" => {t: [3,8], a: nil, b: "Notated music"},
"Print with autograph annotations" => {t: [3,8], a: nil, b: "Notated music"},
"Print with non-autograph annotations" => {t: [3,8], a: nil, b: "Notated music"},
"Libretto, printed" => {t: [5,9], a: "Print", b: "Libretto"},
"Treatise, printed" => {t: [7,10], a: "Print", b: "Treatise"},
"Composite" => {t: [11], a: "Composite", b: "Mixed"},
"Other" => {t: [0], a: nil, b: "Other"} }

TEMPLATES = {
  1 => ["Manuscript copy", "Notated music"],
  2 => ["Manuscript copy", "Notated music"],
  3 => ["Print", "Notated music"],
  4 => ["Manuscript copy", "Libretto"],
  5 => ["Print", "Libretto"],
  6 => ["Manuscript copy", "Treatise"],
  7 => ["Print", "Treatise"],
  8 => ["Print", "Notated music"],
  9 => ["Print", "Libretto"],
  10 => ["Print", "Treatise"],
  11 => ["Composite", "Mixed"],
}

require_relative "lib/maintenance"
logfile = "#{File.dirname($0)}/log/#{File.basename($0, '.rb')}.log"
File.delete(logfile) if File.exist?(logfile)
logger = Logger.new(logfile)
host = Socket.gethostname
PaperTrail.request.disable_model(Source)
PaperTrail.request.disable_model(Holding)
collection = Source.find_each + Holding.find_each
bar = ProgressBar.new(collection.size)

collection.each do |record|
  bar.increment!
  record.suppress_reindex
  if record.has_attribute?(:record_type)
    template = record.record_type
  else
    template = 3
  end
  klass = record.class
  parent = record.source_id ? "#{record.source_id}:" : ""

  # Create 593 from template if there isn't one
  if !record.marc.has_tag?("593")
    new_593 = MarcNode.new(klass, "593", "", "##")
    ip = record.marc.get_insert_position("593")
    new_593.add(MarcNode.new(klass, "a", TEMPLATES[template][0], nil))
    new_593.add(MarcNode.new(klass, "b", TEMPLATES[template][1], nil))
    new_593.add(MarcNode.new(klass, "8", "01", nil))
    record.marc.root.children.insert(ip, new_593)
    logger.info("'#{host}','#{klass}','#{parent}#{record.id}','CREATED','#{new_593}'")
  else
    record.marc.each_by_tag("593") do |node|
      subfield_a = node.fetch_first_by_tag("a")
      if subfield_a && subfield_a.content
        cfg = CONF[subfield_a.content]
        if !cfg
          raise Exception.new "#{record.id} '#{node}': False value"
        else
          a_value = cfg[:a]
          if a_value
            subfield_a.content = a_value            
          end
          b_value = cfg[:b]
          action = "ADDED"
          node.add(MarcNode.new(klass, "b", "#{b_value}", nil))
        end
      else
        action = "ERROR EMPTY TAG"
      end
      node.sort_alphabetically
      logger.info("'#{host}','#{klass}','#{parent}#{record.id}','#{action}','#{node}'")
    end
  end
  record.save
end

