# frozen_string_literal: true

class Clover
  def private_subnet_list
    dataset = dataset_authorize(@project.private_subnets_dataset, "PrivateSubnet:view")

    if api?
      dataset = dataset.where(location: @location) if @location
      result = dataset.eager(nics: [:private_subnet]).paginated_result(
        start_after: request.params["start_after"],
        page_size: request.params["page_size"],
        order_column: request.params["order_column"]
      )

      {
        items: Serializers::PrivateSubnet.serialize(result[:records]),
        count: result[:count]
      }
    else
      @pss = Serializers::PrivateSubnet.serialize(dataset.all, {include_path: true})
      view "networking/private_subnet/index"
    end
  end

  def private_subnet_post(name)
    authorize("PrivateSubnet:create", @project.id)

    required_parameters = []
    required_parameters << "name" << "location" if web?
    request_body_params = validate_request_params(required_parameters, ["firewall_id"])
    firewall_id = if request_body_params["firewall_id"]
      fw = Firewall.from_ubid(request_body_params["firewall_id"])
      unless fw && fw.location_id == @location.id
        fail Validation::ValidationFailed.new(firewall_id: "Firewall with id \"#{request_body_params["firewall_id"]}\" and location \"#{@location.display_name}\" is not found")
      end
      authorize("Firewall:view", fw.id)
      fw.id
    end

    st = Prog::Vnet::SubnetNexus.assemble(
      @project.id,
      name:,
      location_id: @location.id,
      firewall_id:
    )

    if api?
      Serializers::PrivateSubnet.serialize(st.subject)
    else
      flash["notice"] = "'#{name}' will be ready in a few seconds"
      request.redirect "#{@project.path}#{PrivateSubnet[st.id].path}"
    end
  end

  def generate_private_subnet_options
    options = OptionTreeGenerator.new
    options.add_option(name: "name")
    options.add_option(name: "location", values: Option.locations)
    options.serialize
  end
end
