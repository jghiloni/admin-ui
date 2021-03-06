require 'time'
require 'yajl'
require_relative '../spec_helper'
require_relative 'cc_helper'
require_relative 'nats_helper'
require_relative 'varz_helper'

module ViewModelsHelper
  include CCHelper
  include DopplerHelper
  include NATSHelper
  include VARZHelper

  BILLION = 1000 * 1000 * 1000

  def view_models_stub(application_instance_source)
    @application_instance_source = application_instance_source

    @used_memory_in_bytes = determine_used_memory(application_instance_source)
    @used_disk_in_bytes = determine_used_disk(application_instance_source)
    @computed_pcpu = determine_used_cpu(application_instance_source)

    @dea_identity = if application_instance_source == :varz_dea
                      nats_dea['host']
                    elsif application_instance_source == :doppler_dea
                      "#{dea_envelope.ip}:#{dea_envelope.index}"
                    end
  end

  def determine_used_cpu(application_instance_source)
    if application_instance_source == :varz_dea
      varz_dea['instance_registry'][cc_app[:guid]][varz_dea_app_instance]['computed_pcpu'] * 100
    elsif application_instance_source == :doppler_cell
      rep_container_metric_envelope.containerMetric.cpuPercentage
    else
      dea_container_metric_envelope.containerMetric.cpuPercentage
    end
  end

  def determine_used_disk(application_instance_source)
    if application_instance_source == :varz_dea
      varz_dea['instance_registry'][cc_app[:guid]][varz_dea_app_instance]['used_disk_in_bytes']
    elsif application_instance_source == :doppler_cell
      rep_container_metric_envelope.containerMetric.diskBytes
    else
      dea_container_metric_envelope.containerMetric.diskBytes
    end
  end

  def determine_used_memory(application_instance_source)
    if application_instance_source == :varz_dea
      varz_dea['instance_registry'][cc_app[:guid]][varz_dea_app_instance]['used_memory_in_bytes']
    elsif application_instance_source == :doppler_cell
      rep_container_metric_envelope.containerMetric.memoryBytes
    else
      dea_container_metric_envelope.containerMetric.memoryBytes
    end
  end

  def view_models_application_instances
    [
      [
        "#{cc_app[:guid]}/#{cc_app_instance_index}",
        cc_app[:name],
        cc_app[:guid],
        cc_app_instance_index,
        @application_instance_source == :varz_dea ? varz_dea_app_instance : nil,
        @application_instance_source == :varz_dea ? varz_dea['instance_registry'][cc_app[:guid]][varz_dea_app_instance]['state'] : nil,
        @application_instance_source == :varz_dea ? Time.at(varz_dea['instance_registry'][cc_app[:guid]][varz_dea_app_instance]['state_running_timestamp']).to_datetime.rfc3339 : nil,
        @application_instance_source == :varz_dea ? nil : Time.at(rep_envelope.timestamp / BILLION).to_datetime.rfc3339,
        @application_instance_source == :doppler_cell,
        cc_stack[:name],
        AdminUI::Utils.convert_bytes_to_megabytes(@used_memory_in_bytes),
        AdminUI::Utils.convert_bytes_to_megabytes(@used_disk_in_bytes),
        @computed_pcpu,
        cc_app[:memory],
        cc_app[:disk_quota],
        "#{cc_organization[:name]}/#{cc_space[:name]}",
        @dea_identity,
        @application_instance_source == :doppler_cell ? "#{rep_envelope.ip}:#{rep_envelope.index}" : nil,
        @application_instance_source == :varz_dea ? "#{cc_app[:guid]}/#{cc_app_instance_index}/#{varz_dea_app_instance}" : "#{cc_app[:guid]}/#{cc_app_instance_index}/0"
      ]
    ]
  end

  def view_models_application_instances_detail
    container = nil
    if @application_instance_source == :doppler_cell
      container =
        {
          application_id:     rep_container_metric_envelope.containerMetric.applicationId,
          cpu_percentage:     rep_container_metric_envelope.containerMetric.cpuPercentage,
          disk_bytes:         rep_container_metric_envelope.containerMetric.diskBytes,
          disk_bytes_quota:   rep_container_metric_envelope.containerMetric.diskBytesQuota,
          index:              rep_envelope.index,
          instance_index:     rep_container_metric_envelope.containerMetric.instanceIndex,
          ip:                 rep_envelope.ip,
          memory_bytes:       rep_container_metric_envelope.containerMetric.memoryBytes,
          memory_bytes_quota: rep_container_metric_envelope.containerMetric.memoryBytesQuota,
          origin:             rep_envelope.origin,
          timestamp:          rep_envelope.timestamp
        }
    elsif @application_instance_source == :doppler_dea
      container =
        {
          application_id:     dea_container_metric_envelope.containerMetric.applicationId,
          cpu_percentage:     dea_container_metric_envelope.containerMetric.cpuPercentage,
          disk_bytes:         dea_container_metric_envelope.containerMetric.diskBytes,
          disk_bytes_quota:   dea_container_metric_envelope.containerMetric.diskBytesQuota,
          index:              dea_envelope.index,
          instance_index:     dea_container_metric_envelope.containerMetric.instanceIndex,
          ip:                 dea_envelope.ip,
          memory_bytes:       dea_container_metric_envelope.containerMetric.memoryBytes,
          memory_bytes_quota: dea_container_metric_envelope.containerMetric.memoryBytesQuota,
          origin:             dea_envelope.origin,
          timestamp:          dea_envelope.timestamp
        }
    end

    {
      'application'          => @application_instance_source == :varz_dea ? nil : cc_app,
      'application_instance' => @application_instance_source == :varz_dea ? varz_dea['instance_registry'][cc_app[:guid]][varz_dea_app_instance] : nil,
      'container'            => container,
      'organization'         => cc_organization,
      'space'                => cc_space,
      'stack'                => cc_stack
    }
  end

  def view_models_applications
    [
      [
        cc_app[:guid],
        cc_app[:name],
        cc_app[:guid],
        cc_app[:state],
        cc_app[:package_state],
        cc_app[:staging_failed_reason],
        cc_app[:created_at].to_datetime.rfc3339,
        cc_app[:updated_at].to_datetime.rfc3339,
        cc_app[:diego],
        cc_app[:enable_ssh],
        !cc_app[:docker_image].nil?,
        cc_stack[:name],
        cc_app[:detected_buildpack],
        cc_app[:detected_buildpack_guid],
        1,
        cc_app[:instances],
        1,
        1,
        AdminUI::Utils.convert_bytes_to_megabytes(@used_memory_in_bytes),
        AdminUI::Utils.convert_bytes_to_megabytes(@used_disk_in_bytes),
        @computed_pcpu,
        cc_app[:memory],
        cc_app[:disk_quota],
        "#{cc_organization[:name]}/#{cc_space[:name]}"
      ]
    ]
  end

  def view_models_applications_detail
    {
      'application'  => cc_app,
      'droplet'      => cc_droplet,
      'organization' => cc_organization,
      'space'        => cc_space,
      'stack'        => cc_stack
    }
  end

  def view_models_approvals
    [
      [
        uaa_user[:username],
        uaa_approval[:user_id],
        uaa_approval[:client_id],
        uaa_approval[:scope],
        uaa_approval[:status],
        uaa_approval[:lastmodifiedat].to_datetime.rfc3339,
        uaa_approval[:expiresat].to_datetime.rfc3339
      ]
    ]
  end

  def view_models_approvals_detail
    {
      'approval' => uaa_approval,
      'user_uaa' => uaa_user
    }
  end

  def view_models_buildpacks
    [
      [
        cc_buildpack[:guid],
        cc_buildpack[:name],
        cc_buildpack[:guid],
        cc_buildpack[:created_at].to_datetime.rfc3339,
        cc_buildpack[:updated_at].to_datetime.rfc3339,
        cc_buildpack[:position],
        cc_buildpack[:enabled],
        cc_buildpack[:locked],
        1
      ]
    ]
  end

  def view_models_buildpacks_detail
    cc_buildpack
  end

  def view_models_cells
    [
      [
        "#{rep_envelope.ip}:#{rep_envelope.index}",
        rep_envelope.ip,
        rep_envelope.index,
        'doppler',
        Time.at(rep_envelope.timestamp / BILLION).to_datetime.rfc3339,
        'RUNNING',
        REP_VALUE_METRICS['numCPUS'],
        AdminUI::Utils.convert_bytes_to_megabytes(REP_VALUE_METRICS['memoryStats.numBytesAllocated']),
        AdminUI::Utils.convert_bytes_to_megabytes(REP_VALUE_METRICS['memoryStats.numBytesAllocatedHeap']),
        AdminUI::Utils.convert_bytes_to_megabytes(REP_VALUE_METRICS['memoryStats.numBytesAllocatedStack']),
        REP_VALUE_METRICS['CapacityTotalContainers'],
        REP_VALUE_METRICS['CapacityRemainingContainers'],
        REP_VALUE_METRICS['ContainerCount'],
        REP_VALUE_METRICS['CapacityTotalMemory'],
        REP_VALUE_METRICS['CapacityRemainingMemory'],
        REP_VALUE_METRICS['CapacityTotalDisk'],
        REP_VALUE_METRICS['CapacityRemainingDisk']
      ]
    ]
  end

  def view_models_cells_detail
    {
      'connected' => true,
      'index'     => rep_envelope.index,
      'ip'        => rep_envelope.ip,
      'origin'    => rep_envelope.origin,
      'timestamp' => rep_envelope.timestamp
    }.merge(REP_VALUE_METRICS)
  end

  def view_models_clients
    [
      [
        uaa_client[:client_id],
        uaa_identity_zone[:name],
        uaa_client[:client_id],
        uaa_client[:lastmodified].to_datetime.rfc3339,
        uaa_client[:scope].split(',').sort,
        uaa_client[:authorized_grant_types].split(',').sort,
        uaa_client[:web_server_redirect_uri].split(',').sort,
        uaa_client[:authorities].split(',').sort,
        [uaa_client_autoapprove.to_s],
        uaa_client[:access_token_validity],
        uaa_client[:refresh_token_validity],
        1,
        1,
        cc_service_broker[:name]
      ]
    ]
  end

  def view_models_clients_detail
    {
      'client'         => uaa_client,
      'identity_zone'  => uaa_identity_zone,
      'service_broker' => cc_service_broker
    }
  end

  def view_models_cloud_controllers
    [
      [
        nats_cloud_controller['host'],
        nats_cloud_controller['index'],
        'varz',
        'RUNNING',
        DateTime.parse(varz_cloud_controller['start']).rfc3339,
        varz_cloud_controller['num_cores'],
        varz_cloud_controller['cpu'],
        AdminUI::Utils.convert_kilobytes_to_megabytes(varz_cloud_controller['mem'])
      ]
    ]
  end

  def view_models_cloud_controllers_detail
    {
      'connected' => true,
      'data'      => varz_cloud_controller,
      'index'     => nats_cloud_controller['index'],
      'name'      => nats_cloud_controller['host'],
      'type'      => nats_cloud_controller['type'],
      'uri'       => nats_cloud_controller_varz
    }
  end

  def view_models_components
    [
      [
        nats_cloud_controller['host'],
        nats_cloud_controller['type'],
        nats_cloud_controller['index'],
        'varz',
        nil,
        'RUNNING',
        DateTime.parse(varz_cloud_controller['start']).rfc3339,
        nats_cloud_controller['host'],
        nats_cloud_controller_varz
      ],
      [
        nats_dea['host'],
        nats_dea['type'],
        nats_dea['index'],
        'varz',
        nil,
        'RUNNING',
        DateTime.parse(varz_dea['start']).rfc3339,
        nats_dea['host'],
        nats_dea_varz
      ],
      [
        "#{doppler_server_envelope.ip}:#{doppler_server_envelope.index}",
        doppler_server_envelope.origin,
        doppler_server_envelope.index,
        'doppler',
        Time.at(doppler_server_envelope.timestamp / BILLION).to_datetime.rfc3339,
        'RUNNING',
        nil,
        "#{doppler_server_envelope.origin}:#{doppler_server_envelope.index}:#{doppler_server_envelope.ip}",
        "#{doppler_server_envelope.origin}:#{doppler_server_envelope.index}:#{doppler_server_envelope.ip}"
      ],
      [
        nats_health_manager['host'],
        nats_health_manager['type'],
        nats_health_manager['index'],
        'varz',
        nil,
        'RUNNING',
        nil,
        nats_health_manager['host'],
        nats_health_manager_varz
      ],
      [
        nats_provisioner['host'],
        nats_provisioner['type'],
        nats_provisioner['index'],
        'varz',
        nil,
        'RUNNING',
        DateTime.parse(varz_provisioner['start']).rfc3339,
        nats_provisioner['host'],
        nats_provisioner_varz
      ],
      [
        nats_router['host'],
        nats_router['type'],
        nats_router['index'],
        'varz',
        nil,
        'RUNNING',
        DateTime.parse(varz_router['start']).rfc3339,
        nats_router['host'],
        nats_router_varz
      ]
    ]
  end

  def view_models_components_detail
    {
      'doppler_component' => nil,
      'varz_component'    => view_models_cloud_controllers_detail
    }
  end

  def view_models_deas
    [
      [
        application_instance_source == :varz_dea ? nats_dea['host'] : "#{dea_envelope.ip}:#{dea_envelope.index}",
        application_instance_source == :varz_dea ? nats_dea['index'] : dea_envelope.index,
        application_instance_source == :varz_dea ? 'varz' : 'doppler',
        @application_instance_source == :doppler_dea ? Time.at(dea_envelope.timestamp / BILLION).to_datetime.rfc3339 : nil,
        'RUNNING',
        application_instance_source == :varz_dea ? DateTime.parse(varz_dea['start']).rfc3339 : nil,
        application_instance_source == :varz_dea ? varz_dea['stacks'] : nil,
        application_instance_source == :varz_dea ? varz_dea['cpu'] : nil,
        application_instance_source == :varz_dea ? AdminUI::Utils.convert_kilobytes_to_megabytes(varz_dea['mem']) : nil,
        application_instance_source == :varz_dea ? varz_dea['instance_registry'].length : DEA_VALUE_METRICS['instances'],
        application_instance_source == :varz_dea ? varz_dea['instance_registry'][cc_app[:guid]].length : cc_app[:instances],
        AdminUI::Utils.convert_bytes_to_megabytes(@used_memory_in_bytes),
        AdminUI::Utils.convert_bytes_to_megabytes(@used_disk_in_bytes),
        @computed_pcpu,
        application_instance_source == :varz_dea ? varz_dea['available_memory_ratio'] * 100 : DEA_VALUE_METRICS['available_memory_ratio'] * 100,
        application_instance_source == :varz_dea ? varz_dea['available_disk_ratio'] * 100 : DEA_VALUE_METRICS['available_disk_ratio'] * 100,
        application_instance_source == :doppler_dea ? DEA_VALUE_METRICS['remaining_memory'] : nil,
        application_instance_source == :doppler_dea ? DEA_VALUE_METRICS['remaining_disk'] : nil
      ]
    ]
  end

  def view_models_deas_detail
    doppler_dea_hash = nil
    varz_dea_hash    = nil

    if application_instance_source == :doppler_dea
      doppler_dea_hash =
        {
          'connected' => true,
          'index'     => dea_envelope.index,
          'ip'        => dea_envelope.ip,
          'origin'    => dea_envelope.origin,
          'timestamp' => dea_envelope.timestamp
        }.merge(DEA_VALUE_METRICS)
    end

    if application_instance_source == :varz_dea
      varz_dea_hash =
        {
          'connected' => true,
          'data'      => varz_dea,
          'index'     => nats_dea['index'],
          'name'      => nats_dea['host'],
          'type'      => nats_dea['type'],
          'uri'       => nats_dea_varz
        }
    end

    {
      'doppler_dea' => doppler_dea_hash,
      'varz_dea'    => varz_dea_hash
    }
  end

  def view_models_domains
    [
      [
        cc_domain[:guid],
        cc_domain[:name],
        cc_domain[:guid],
        cc_domain[:created_at].to_datetime.rfc3339,
        cc_domain[:updated_at].to_datetime.rfc3339,
        cc_organization[:name],
        1,
        1
      ]
    ]
  end

  def view_models_domains_detail
    {
      'domain'                       => cc_domain,
      'owning_organization'          => cc_organization,
      'private_shared_organizations' => [cc_organization]
    }
  end

  def view_models_events
    [
      [
        cc_event_space[:timestamp].to_datetime.rfc3339,
        cc_event_space[:guid],
        cc_event_space[:type],
        cc_event_space[:actee_type],
        cc_event_space[:actee_name],
        cc_event_space[:actee],
        cc_event_space[:actor_type],
        cc_event_space[:actor_name],
        cc_event_space[:actor],
        "#{cc_organization[:name]}/#{cc_space[:name]}"
      ]
    ]
  end

  def view_models_events_detail
    {
      'event'        => cc_event_space,
      'organization' => cc_organization,
      'space'        => cc_space
    }
  end

  def view_models_feature_flags
    [
      [
        cc_feature_flag[:name],
        cc_feature_flag[:name],
        cc_feature_flag[:guid],
        cc_feature_flag[:created_at].to_datetime.rfc3339,
        cc_feature_flag[:updated_at].to_datetime.rfc3339,
        cc_feature_flag[:enabled]
      ]
    ]
  end

  def view_models_feature_flags_detail
    cc_feature_flag
  end

  def view_models_gateways
    [
      [
        nats_provisioner['type'].sub('-Provisioner', ''),
        nats_provisioner['index'],
        'varz',
        'RUNNING',
        DateTime.parse(varz_provisioner['start']).rfc3339,
        varz_provisioner['config']['service']['description'],
        varz_provisioner['cpu'],
        AdminUI::Utils.convert_kilobytes_to_megabytes(varz_provisioner['mem']),
        varz_provisioner['nodes'].length,
        10
      ]
    ]
  end

  def view_models_gateways_detail
    {
      'connected' => true,
      'data'      => varz_provisioner,
      'index'     => nats_provisioner['index'],
      'name'      => nats_provisioner['type'].sub('-Provisioner', ''),
      'type'      => nats_provisioner['type'],
      'uri'       => nats_provisioner_varz
    }
  end

  def view_models_group_members
    [
      [
        uaa_group[:displayname],
        uaa_group[:id],
        uaa_user[:username],
        uaa_approval[:user_id],
        uaa_group_membership[:added].to_datetime.rfc3339
      ]
    ]
  end

  def view_models_group_members_detail
    {
      'group'            => uaa_group,
      'group_membership' => uaa_group_membership,
      'user_uaa'         => uaa_user
    }
  end

  def view_models_groups
    [
      [
        uaa_group[:id],
        uaa_identity_zone[:name],
        uaa_group[:displayname],
        uaa_group[:id],
        uaa_group[:created].to_datetime.rfc3339,
        uaa_group[:lastmodified].to_datetime.rfc3339,
        uaa_group[:version],
        1
      ]
    ]
  end

  def view_models_groups_detail
    {
      'group'         => uaa_group,
      'identity_zone' => uaa_identity_zone
    }
  end

  def view_models_health_managers
    [
      [
        @application_instance_source == :doppler_dea ? "#{analyzer_envelope.ip}:#{analyzer_envelope.index}" : nats_health_manager['host'],
        @application_instance_source == :doppler_dea ? analyzer_envelope.index : nats_health_manager['index'],
        @application_instance_source == :doppler_dea ? 'doppler' : 'varz',
        @application_instance_source == :doppler_dea ? Time.at(analyzer_envelope.timestamp / BILLION).to_datetime.rfc3339 : nil,
        'RUNNING',
        @application_instance_source == :doppler_dea ? ANALYZER_VALUE_METRICS['numCPUS'] : varz_health_manager['numCPUS'],
        @application_instance_source == :doppler_dea ? AdminUI::Utils.convert_bytes_to_megabytes(ANALYZER_VALUE_METRICS['memoryStats.numBytesAllocated']) : AdminUI::Utils.convert_bytes_to_megabytes(varz_health_manager['memoryStats']['numBytesAllocated'])
      ]
    ]
  end

  def view_models_health_managers_detail
    doppler_analyzer_hash    = nil
    varz_health_manager_hash = nil

    if application_instance_source == :doppler_dea
      doppler_analyzer_hash =
        {
          'connected' => true,
          'index'     => analyzer_envelope.index,
          'ip'        => analyzer_envelope.ip,
          'origin'    => analyzer_envelope.origin,
          'timestamp' => analyzer_envelope.timestamp
        }.merge(ANALYZER_VALUE_METRICS)
    else
      varz_health_manager_hash =
        {
          'connected' => true,
          'data'      => varz_health_manager,
          'index'     => nats_health_manager['index'],
          'name'      => nats_health_manager['host'],
          'type'      => nats_health_manager['type'],
          'uri'       => nats_health_manager_varz
        }
    end

    {
      'doppler_analyzer'    => doppler_analyzer_hash,
      'varz_health_manager' => varz_health_manager_hash
    }
  end

  def view_models_identity_providers
    [
      [
        uaa_identity_zone[:name],
        uaa_identity_provider[:name],
        uaa_identity_provider[:id],
        uaa_identity_provider[:created].to_datetime.rfc3339,
        uaa_identity_provider[:lastmodified].to_datetime.rfc3339,
        uaa_identity_provider[:origin_key],
        uaa_identity_provider[:type],
        uaa_identity_provider[:active],
        uaa_identity_provider[:version]
      ]
    ]
  end

  def view_models_identity_providers_detail
    {
      'identity_provider' => uaa_identity_provider,
      'identity_zone'     => uaa_identity_zone
    }
  end

  def view_models_identity_zones
    [
      [
        uaa_identity_zone[:name],
        uaa_identity_zone[:id],
        uaa_identity_zone[:created].to_datetime.rfc3339,
        uaa_identity_zone[:lastmodified].to_datetime.rfc3339,
        uaa_identity_zone[:subdomain],
        uaa_identity_zone[:version],
        1,
        1,
        1,
        uaa_identity_zone[:description]
      ]
    ]
  end

  def view_models_identity_zones_detail
    uaa_identity_zone
  end

  def view_models_logs(log_file_displayed, log_file_displayed_contents_length, log_file_displayed_modified_milliseconds)
    [
      [
        log_file_displayed,
        log_file_displayed_contents_length,
        Time.at(log_file_displayed_modified_milliseconds / 1000.0).to_datetime.rfc3339,
        {
          path: log_file_displayed,
          size: log_file_displayed_contents_length,
          time: log_file_displayed_modified_milliseconds
        }
      ]
    ]
  end

  def view_models_organizations
    [
      [
        cc_organization[:guid],
        cc_organization[:name],
        cc_organization[:guid],
        cc_organization[:status],
        cc_organization[:created_at].to_datetime.rfc3339,
        cc_organization[:updated_at].to_datetime.rfc3339,
        1,
        1,
        4,
        3,
        1,
        cc_quota_definition[:name],
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        0,
        cc_app[:instances],
        1,
        AdminUI::Utils.convert_bytes_to_megabytes(@used_memory_in_bytes),
        AdminUI::Utils.convert_bytes_to_megabytes(@used_disk_in_bytes),
        @computed_pcpu,
        cc_app[:memory],
        cc_app[:disk_quota],
        1,
        cc_app[:state] == 'STARTED' ? 1 : 0,
        cc_app[:state] == 'STOPPED' ? 1 : 0,
        cc_app[:package_state] == 'PENDING' ? 1 : 0,
        cc_app[:package_state] == 'STAGED' ? 1 : 0,
        cc_app[:package_state] == 'FAILED' ? 1 : 0
      ]
    ]
  end

  def view_models_organizations_detail
    {
      'organization'     => cc_organization,
      'quota_definition' => cc_quota_definition
    }
  end

  def view_models_organization_roles
    [
      [
        "#{cc_organization[:guid]}/auditors/#{uaa_user[:id]}",
        cc_organization[:name],
        cc_organization[:guid],
        uaa_user[:username],
        uaa_user[:id],
        'Auditor'
      ],
      [
        "#{cc_organization[:guid]}/billing_managers/#{uaa_user[:id]}",
        cc_organization[:name],
        cc_organization[:guid],
        uaa_user[:username],
        uaa_user[:id],
        'Billing Manager'
      ],
      [
        "#{cc_organization[:guid]}/managers/#{uaa_user[:id]}",
        cc_organization[:name],
        cc_organization[:guid],
        uaa_user[:username],
        uaa_user[:id],
        'Manager'
      ],
      [
        "#{cc_organization[:guid]}/users/#{uaa_user[:id]}",
        cc_organization[:name],
        cc_organization[:guid],
        uaa_user[:username],
        uaa_user[:id],
        'User'
      ]
    ]
  end

  def view_models_organization_roles_detail
    {
      'organization' => cc_organization,
      'role'         => cc_organization_auditor,
      'user_cc'      => cc_user,
      'user_uaa'     => uaa_user
    }
  end

  def view_models_quotas
    [
      [
        cc_quota_definition[:guid],
        cc_quota_definition[:name],
        cc_quota_definition[:guid],
        cc_quota_definition[:created_at].to_datetime.rfc3339,
        cc_quota_definition[:updated_at].to_datetime.rfc3339,
        cc_quota_definition[:total_private_domains],
        cc_quota_definition[:total_services],
        cc_quota_definition[:total_service_keys],
        cc_quota_definition[:total_routes],
        cc_quota_definition[:total_reserved_route_ports],
        cc_quota_definition[:app_instance_limit],
        cc_quota_definition[:app_task_limit],
        cc_quota_definition[:memory_limit],
        cc_quota_definition[:instance_memory_limit],
        cc_quota_definition[:non_basic_services_allowed],
        1
      ]
    ]
  end

  def view_models_quotas_detail
    cc_quota_definition
  end

  def view_models_routers
    [
      [
        @application_instance_source == :doppler_dea ? "#{gorouter_envelope.ip}:#{gorouter_envelope.index}" : nats_router['host'],
        @application_instance_source == :doppler_dea ? gorouter_envelope.index : nats_router['index'],
        @application_instance_source == :doppler_dea ? 'doppler' : 'varz',
        @application_instance_source == :doppler_dea ? Time.at(gorouter_envelope.timestamp / BILLION).to_datetime.rfc3339 : nil,
        'RUNNING',
        @application_instance_source == :doppler_dea ? nil : DateTime.parse(varz_router['start']).rfc3339,
        @application_instance_source == :doppler_dea ? GOROUTER_VALUE_METRICS['numCPUS'] : varz_router['num_cores'],
        @application_instance_source == :doppler_dea ? nil : varz_router['cpu'],
        @application_instance_source == :doppler_dea ? AdminUI::Utils.convert_bytes_to_megabytes(GOROUTER_VALUE_METRICS['memoryStats.numBytesAllocated']) : AdminUI::Utils.convert_kilobytes_to_megabytes(varz_router['mem']),
        @application_instance_source == :doppler_dea ? nil : varz_router['droplets'],
        @application_instance_source == :doppler_dea ? nil : varz_router['requests'],
        @application_instance_source == :doppler_dea ? nil : varz_router['bad_requests']
      ]
    ]
  end

  def view_models_routers_detail
    doppler_gorouter_hash = nil
    varz_router_hash      = nil
    top10_apps_array      = nil

    if application_instance_source == :doppler_dea
      doppler_gorouter_hash =
        {
          'connected' => true,
          'index'     => gorouter_envelope.index,
          'ip'        => gorouter_envelope.ip,
          'origin'    => gorouter_envelope.origin,
          'timestamp' => gorouter_envelope.timestamp
        }.merge(GOROUTER_VALUE_METRICS)
    else
      varz_router_hash =
        {
          'connected' => true,
          'data'      => varz_router,
          'index'     => nats_router['index'],
          'name'      => nats_router['host'],
          'type'      => nats_router['type'],
          'uri'       => nats_router_varz
        }

      top10_apps_array =
        [
          {
            'guid'   => cc_app[:guid],
            'name'   => cc_app[:name],
            'rpm'    => varz_router['top10_app_requests'][0]['rpm'],
            'rps'    => varz_router['top10_app_requests'][0]['rps'],
            'target' => "#{cc_organization[:name]}/#{cc_space[:name]}"
          }
        ]

    end

    {
      'doppler_gorouter' => doppler_gorouter_hash,
      'varz_router'      => varz_router_hash,
      'top_10_apps'      => top10_apps_array
    }
  end

  def view_models_route_mappings
    [
      [
        cc_app_route[:guid],
        cc_app_route[:guid],
        cc_app_route[:created_at].to_datetime.rfc3339,
        cc_app_route[:updated_at].to_datetime.rfc3339,
        cc_app[:name],
        cc_app[:guid],
        "http://#{cc_route[:host]}.#{cc_domain[:name]}#{cc_route[:path]}",
        cc_route[:guid],
        "#{cc_organization[:name]}/#{cc_space[:name]}"
      ]
    ]
  end

  def view_models_route_mappings_detail
    {
      'application'  => cc_app,
      'app_route'    => cc_app_route,
      'domain'       => cc_domain,
      'organization' => cc_organization,
      'route'        => cc_route,
      'space'        => cc_space
    }
  end

  def view_models_routes
    [
      [
        cc_route[:guid],
        "http://#{cc_route[:host]}.#{cc_domain[:name]}#{cc_route[:path]}",
        cc_route[:host],
        cc_domain[:name],
        nil,
        cc_route[:path],
        cc_route[:guid],
        cc_route[:created_at].to_datetime.rfc3339,
        cc_route[:updated_at].to_datetime.rfc3339,
        1,
        1,
        "#{cc_organization[:name]}/#{cc_space[:name]}"
      ]
    ]
  end

  def view_models_routes_detail
    {
      'domain'       => cc_domain,
      'organization' => cc_organization,
      'route'        => cc_route,
      'space'        => cc_space
    }
  end

  def view_models_security_groups
    [
      [
        cc_security_group[:guid],
        cc_security_group[:name],
        cc_security_group[:guid],
        cc_security_group[:created_at].to_datetime.rfc3339,
        cc_security_group[:updated_at].to_datetime.rfc3339,
        cc_security_group[:staging_default],
        cc_security_group[:running_default],
        1
      ]
    ]
  end

  def view_models_security_groups_detail
    cc_security_group
  end

  def view_models_security_groups_spaces
    [
      [
        "#{cc_security_group[:guid]}/#{cc_space[:guid]}",
        cc_security_group[:name],
        cc_security_group[:guid],
        cc_security_group[:created_at].to_datetime.rfc3339,
        cc_security_group[:updated_at].to_datetime.rfc3339,
        cc_space[:name],
        cc_space[:guid],
        cc_space[:created_at].to_datetime.rfc3339,
        cc_space[:updated_at].to_datetime.rfc3339,
        "#{cc_organization[:name]}/#{cc_space[:name]}"
      ]
    ]
  end

  def view_models_security_groups_spaces_detail
    {
      'organization'         => cc_organization,
      'security_group'       => cc_security_group,
      'security_group_space' => cc_security_group_space,
      'space'                => cc_space
    }
  end

  def view_models_service_bindings
    [
      [
        cc_service_binding[:guid],
        cc_service_binding[:guid],
        cc_service_binding[:created_at].to_datetime.rfc3339,
        cc_service_binding[:updated_at].to_datetime.rfc3339,
        !cc_service_binding[:syslog_drain_url].nil? && cc_service_binding[:syslog_drain_url].length.positive?,
        1,
        cc_app[:name],
        cc_app[:guid],
        cc_service_instance[:name],
        cc_service_instance[:guid],
        cc_service_instance[:created_at].to_datetime.rfc3339,
        cc_service_instance[:updated_at].to_datetime.rfc3339,
        cc_service_plan[:name],
        cc_service_plan[:guid],
        cc_service_plan[:unique_id],
        cc_service_plan[:created_at].to_datetime.rfc3339,
        cc_service_plan[:updated_at].to_datetime.rfc3339,
        cc_service_plan[:active],
        cc_service_plan[:public],
        cc_service_plan[:free],
        cc_service[:provider],
        cc_service[:label],
        cc_service[:guid],
        cc_service[:unique_id],
        cc_service[:version],
        cc_service[:created_at].to_datetime.rfc3339,
        cc_service[:updated_at].to_datetime.rfc3339,
        cc_service[:active],
        cc_service_broker[:name],
        cc_service_broker[:guid],
        cc_service_broker[:created_at].to_datetime.rfc3339,
        cc_service_broker[:updated_at].to_datetime.rfc3339,
        "#{cc_organization[:name]}/#{cc_space[:name]}"
      ]
    ]
  end

  def view_models_service_bindings_detail
    {
      'application'      => cc_app,
      'organization'     => cc_organization,
      'service'          => cc_service,
      'service_binding'  => cc_service_binding,
      'service_broker'   => cc_service_broker,
      'service_instance' => cc_service_instance,
      'service_plan'     => cc_service_plan,
      'space'            => cc_space
    }
  end

  def view_models_service_brokers
    [
      [
        cc_service_broker[:guid],
        cc_service_broker[:name],
        cc_service_broker[:guid],
        cc_service_broker[:created_at].to_datetime.rfc3339,
        cc_service_broker[:updated_at].to_datetime.rfc3339,
        1,
        uaa_client[:client_id],
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        "#{cc_organization[:name]}/#{cc_space[:name]}"
      ]
    ]
  end

  def view_models_service_brokers_detail
    {
      'organization'   => cc_organization,
      'service_broker' => cc_service_broker,
      'space'          => cc_space
    }
  end

  def view_models_service_instances
    [
      [
        "#{cc_service_instance[:guid]}/#{cc_service_instance[:is_gateway_service]}",
        cc_service_instance[:name],
        cc_service_instance[:guid],
        cc_service_instance[:created_at].to_datetime.rfc3339,
        cc_service_instance[:updated_at].to_datetime.rfc3339,
        !cc_service_instance[:is_gateway_service],
        !cc_service_instance[:syslog_drain_url].nil? && cc_service_instance[:syslog_drain_url].length.positive?,
        1,
        1,
        1,
        cc_service_instance_operation[:type],
        cc_service_instance_operation[:state],
        cc_service_instance_operation[:created_at].to_datetime.rfc3339,
        cc_service_instance_operation[:updated_at].to_datetime.rfc3339,
        cc_service_plan[:name],
        cc_service_plan[:guid],
        cc_service_plan[:unique_id],
        cc_service_plan[:created_at].to_datetime.rfc3339,
        cc_service_plan[:updated_at].to_datetime.rfc3339,
        cc_service_plan[:active],
        cc_service_plan[:public],
        cc_service_plan[:free],
        cc_service[:provider],
        cc_service[:label],
        cc_service[:guid],
        cc_service[:unique_id],
        cc_service[:version],
        cc_service[:created_at].to_datetime.rfc3339,
        cc_service[:updated_at].to_datetime.rfc3339,
        cc_service[:active],
        cc_service[:bindable],
        cc_service_broker[:name],
        cc_service_broker[:guid],
        cc_service_broker[:created_at].to_datetime.rfc3339,
        cc_service_broker[:updated_at].to_datetime.rfc3339,
        "#{cc_organization[:name]}/#{cc_space[:name]}"
      ]
    ]
  end

  def view_models_service_instances_detail
    {
      'organization'               => cc_organization,
      'service'                    => cc_service,
      'service_broker'             => cc_service_broker,
      'service_instance'           => cc_service_instance,
      'service_instance_operation' => cc_service_instance_operation,
      'service_plan'               => cc_service_plan,
      'space'                      => cc_space
    }
  end

  def view_models_service_keys
    [
      [
        cc_service_key[:guid],
        cc_service_key[:name],
        cc_service_key[:guid],
        cc_service_key[:created_at].to_datetime.rfc3339,
        cc_service_key[:updated_at].to_datetime.rfc3339,
        1,
        cc_service_instance[:name],
        cc_service_instance[:guid],
        cc_service_instance[:created_at].to_datetime.rfc3339,
        cc_service_instance[:updated_at].to_datetime.rfc3339,
        cc_service_plan[:name],
        cc_service_plan[:guid],
        cc_service_plan[:unique_id],
        cc_service_plan[:created_at].to_datetime.rfc3339,
        cc_service_plan[:updated_at].to_datetime.rfc3339,
        cc_service_plan[:active],
        cc_service_plan[:public],
        cc_service_plan[:free],
        cc_service[:provider],
        cc_service[:label],
        cc_service[:guid],
        cc_service[:unique_id],
        cc_service[:version],
        cc_service[:created_at].to_datetime.rfc3339,
        cc_service[:updated_at].to_datetime.rfc3339,
        cc_service[:active],
        cc_service_broker[:name],
        cc_service_broker[:guid],
        cc_service_broker[:created_at].to_datetime.rfc3339,
        cc_service_broker[:updated_at].to_datetime.rfc3339,
        "#{cc_organization[:name]}/#{cc_space[:name]}"
      ]
    ]
  end

  def view_models_service_keys_detail
    {
      'organization'     => cc_organization,
      'service'          => cc_service,
      'service_broker'   => cc_service_broker,
      'service_instance' => cc_service_instance,
      'service_key'      => cc_service_key,
      'service_plan'     => cc_service_plan,
      'space'            => cc_space
    }
  end

  def view_models_service_plans
    [
      [
        cc_service_plan[:guid],
        cc_service_plan[:name],
        cc_service_plan[:guid],
        cc_service_plan[:unique_id],
        cc_service_plan[:created_at].to_datetime.rfc3339,
        cc_service_plan[:updated_at].to_datetime.rfc3339,
        cc_service_plan[:active],
        cc_service_plan[:public],
        cc_service_plan[:free],
        cc_service_plan_display_name,
        1,
        1,
        1,
        1,
        1,
        cc_service[:provider],
        cc_service[:label],
        cc_service[:guid],
        cc_service[:unique_id],
        cc_service[:version],
        cc_service[:created_at].to_datetime.rfc3339,
        cc_service[:updated_at].to_datetime.rfc3339,
        cc_service[:active],
        cc_service[:bindable],
        cc_service_broker[:name],
        cc_service_broker[:guid],
        cc_service_broker[:created_at].to_datetime.rfc3339,
        cc_service_broker[:updated_at].to_datetime.rfc3339
      ]
    ]
  end

  def view_models_service_plans_detail
    {
      'service'        => cc_service,
      'service_broker' => cc_service_broker,
      'service_plan'   => cc_service_plan
    }
  end

  def view_models_service_plan_visibilities
    [
      [
        cc_service_plan_visibility[:guid],
        cc_service_plan_visibility[:guid],
        cc_service_plan_visibility[:created_at].to_datetime.rfc3339,
        cc_service_plan_visibility[:updated_at].to_datetime.rfc3339,
        1,
        cc_service_plan[:name],
        cc_service_plan[:guid],
        cc_service_plan[:unique_id],
        cc_service_plan[:created_at].to_datetime.rfc3339,
        cc_service_plan[:updated_at].to_datetime.rfc3339,
        cc_service_plan[:active],
        cc_service_plan[:public],
        cc_service_plan[:free],
        cc_service[:provider],
        cc_service[:label],
        cc_service[:guid],
        cc_service[:unique_id],
        cc_service[:version],
        cc_service[:created_at].to_datetime.rfc3339,
        cc_service[:updated_at].to_datetime.rfc3339,
        cc_service[:active],
        cc_service[:bindable],
        cc_service_broker[:name],
        cc_service_broker[:guid],
        cc_service_broker[:created_at].to_datetime.rfc3339,
        cc_service_broker[:updated_at].to_datetime.rfc3339,
        cc_organization[:name],
        cc_organization[:guid],
        cc_organization[:created_at].to_datetime.rfc3339,
        cc_organization[:updated_at].to_datetime.rfc3339
      ]
    ]
  end

  def view_models_service_plan_visibilities_detail
    {
      'organization'            => cc_organization,
      'service'                 => cc_service,
      'service_broker'          => cc_service_broker,
      'service_plan'            => cc_service_plan,
      'service_plan_visibility' => cc_service_plan_visibility
    }
  end

  def view_models_services
    [
      [
        cc_service[:guid],
        cc_service[:provider],
        cc_service[:label],
        cc_service[:guid],
        cc_service[:unique_id],
        cc_service[:version],
        cc_service[:created_at].to_datetime.rfc3339,
        cc_service[:updated_at].to_datetime.rfc3339,
        cc_service[:active],
        cc_service[:bindable],
        cc_service[:plan_updateable],
        cc_service_provider_display_name,
        cc_service_display_name,
        Yajl::Parser.parse(cc_service[:requires]).sort,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        cc_service_broker[:name],
        cc_service_broker[:guid],
        cc_service_broker[:created_at].to_datetime.rfc3339,
        cc_service_broker[:updated_at].to_datetime.rfc3339
      ]
    ]
  end

  def view_models_services_detail
    {
      'service'        => cc_service,
      'service_broker' => cc_service_broker
    }
  end

  def view_models_space_quotas
    [
      [
        cc_space_quota_definition[:guid],
        cc_space_quota_definition[:name],
        cc_space_quota_definition[:guid],
        cc_space_quota_definition[:created_at].to_datetime.rfc3339,
        cc_space_quota_definition[:updated_at].to_datetime.rfc3339,
        cc_space_quota_definition[:total_services],
        cc_space_quota_definition[:total_service_keys],
        cc_space_quota_definition[:total_routes],
        cc_space_quota_definition[:total_reserved_route_ports],
        cc_space_quota_definition[:app_instance_limit],
        cc_space_quota_definition[:app_task_limit],
        cc_space_quota_definition[:memory_limit],
        cc_space_quota_definition[:instance_memory_limit],
        cc_space_quota_definition[:non_basic_services_allowed],
        1,
        cc_organization[:name],
        cc_organization[:guid]
      ]
    ]
  end

  def view_models_space_quotas_detail
    {
      'organization'           => cc_organization,
      'space_quota_definition' => cc_space_quota_definition
    }
  end

  def view_models_space_roles
    [
      [
        "#{cc_space[:guid]}/auditors/#{uaa_user[:id]}",
        cc_space[:name],
        cc_space[:guid],
        "#{cc_organization[:name]}/#{cc_space[:name]}",
        uaa_user[:username],
        uaa_user[:id],
        'Auditor'
      ],
      [
        "#{cc_space[:guid]}/developers/#{uaa_user[:id]}",
        cc_space[:name],
        cc_space[:guid],
        "#{cc_organization[:name]}/#{cc_space[:name]}",
        uaa_user[:username],
        uaa_user[:id],
        'Developer'
      ],
      [
        "#{cc_space[:guid]}/managers/#{uaa_user[:id]}",
        cc_space[:name],
        cc_space[:guid],
        "#{cc_organization[:name]}/#{cc_space[:name]}",
        uaa_user[:username],
        uaa_user[:id],
        'Manager'
      ]
    ]
  end

  def view_models_space_roles_detail
    {
      'organization' => cc_organization,
      'role'         => cc_space_auditor,
      'space'        => cc_space,
      'user_cc'      => cc_user,
      'user_uaa'     => uaa_user
    }
  end

  def view_models_spaces
    [
      [
        cc_space[:guid],
        cc_space[:name],
        cc_space[:guid],
        "#{cc_organization[:name]}/#{cc_space[:name]}",
        cc_space[:created_at].to_datetime.rfc3339,
        cc_space[:updated_at].to_datetime.rfc3339,
        cc_space[:allow_ssh],
        1,
        1,
        3,
        1,
        cc_space_quota_definition[:name],
        1,
        1,
        1,
        1,
        0,
        cc_app[:instances],
        1,
        AdminUI::Utils.convert_bytes_to_megabytes(@used_memory_in_bytes),
        AdminUI::Utils.convert_bytes_to_megabytes(@used_disk_in_bytes),
        @computed_pcpu,
        cc_app[:memory],
        cc_app[:disk_quota],
        1,
        cc_app[:state] == 'STARTED' ? 1 : 0,
        cc_app[:state] == 'STOPPED' ? 1 : 0,
        cc_app[:package_state] == 'PENDING' ? 1 : 0,
        cc_app[:package_state] == 'STAGED' ? 1 : 0,
        cc_app[:package_state] == 'FAILED' ? 1 : 0
      ]
    ]
  end

  def view_models_spaces_detail
    {
      'organization'           => cc_organization,
      'space'                  => cc_space,
      'space_quota_definition' => cc_space_quota_definition
    }
  end

  def view_models_stacks
    [
      [
        cc_stack[:name],
        cc_stack[:guid],
        cc_stack[:created_at].to_datetime.rfc3339,
        cc_stack[:updated_at].to_datetime.rfc3339,
        1,
        cc_app[:instances],
        cc_stack[:description]
      ]
    ]
  end

  def view_models_stacks_detail
    cc_stack
  end

  def view_models_stats(timestamp)
    [
      [
        Time.at(timestamp / 1000.0).to_datetime.rfc3339,
        1,
        1,
        1,
        1,
        cc_app[:instances],
        cc_app[:state] == 'STARTED' ? 1 : 0,
        @application_instance_source == :varz_dea || @application_instance_source == :doppler_dea ? 1 : 0,
        @application_instance_source == :doppler_cell ? 1 : 0,
        {
          apps:              1,
          cells:             @application_instance_source == :doppler_cell ? 1 : 0,
          deas:              @application_instance_source == :varz_dea || @application_instance_source == :doppler_dea ? 1 : 0,
          organizations:     1,
          running_instances: cc_app[:state] == 'STARTED' ? 1 : 0,
          spaces:            1,
          timestamp:         timestamp,
          total_instances:   cc_app[:instances],
          users:             1
        }
      ]
    ]
  end

  def view_models_users
    [
      [
        uaa_user[:id],
        uaa_identity_zone[:name],
        uaa_user[:username],
        uaa_user[:id],
        uaa_user[:created].to_datetime.rfc3339,
        uaa_user[:lastmodified].to_datetime.rfc3339,
        uaa_user[:passwd_lastmodified].to_datetime.rfc3339,
        uaa_user[:email],
        uaa_user[:familyname],
        uaa_user[:givenname],
        uaa_user[:phonenumber],
        uaa_user[:active],
        uaa_user[:version],
        1,
        1,
        1,
        4,
        1,
        1,
        1,
        1,
        3,
        1,
        1,
        1,
        "#{cc_organization[:name]}/#{cc_space[:name]}"
      ]
    ]
  end

  def view_models_users_detail
    {
      'identity_zone' => uaa_identity_zone,
      'organization'  => cc_organization,
      'space'         => cc_space,
      'user_cc'       => cc_user,
      'user_uaa'      => uaa_user
    }
  end
end
