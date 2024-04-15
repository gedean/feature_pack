MicroResources.groups.each do |group|
  unless group.manifest[:namespace_only]
    # Default "home" route every group has to have.
    get group.manifest[:url],
      to: "#{group.name.name}#home",
      as: group.name.name

    unless group.routes_file.nil?
      scope group.manifest[:url] do
        draw(group.routes_file)
      end
    end
  end

  namespace group.name, path: group.manifest[:url] do
    group.micro_resources.each do |micro_resources|
      scope micro_resources.manifest[:url], as: micro_resources.name.name do
        draw(micro_resources.routes_file)
      end
    end
  end
end
