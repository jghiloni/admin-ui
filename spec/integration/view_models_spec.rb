require 'logger'
require_relative '../spec_helper'

describe AdminUI::ViewModels, type: :integration do
  include ConfigHelper
  include DopplerHelper
  include VARZHelper
  include ViewModelsHelper

  let(:application_instance_source)  { :varz_dea }
  let(:ccdb_file)                    { '/tmp/admin_ui_ccdb.db' }
  let(:ccdb_uri)                     { "sqlite://#{ccdb_file}" }
  let(:data_file)                    { '/tmp/admin_ui_data.json' }
  let(:db_file)                      { '/tmp/admin_ui_store.db' }
  let(:db_uri)                       { "sqlite://#{db_file}" }
  let(:doppler_data_file)            { '/tmp/admin_ui_doppler_data.json' }
  let(:event_type)                   { 'space' }
  let(:log_file)                     { '/tmp/admin_ui.log' }
  let(:log_file_displayed)           { '/tmp/admin_ui_displayed.log' }
  let(:log_file_displayed_contents)  { 'These are test log file contents' }
  let(:log_file_displayed_modified)  { Time.new(1976, 7, 4, 12, 34, 56, 0) }
  let(:uaadb_file)                   { '/tmp/admin_ui_uaadb.db' }
  let(:uaadb_uri)                    { "sqlite://#{uaadb_file}" }
  let(:varz_application_instance_id) { application_instance_source == :varz_dea ? varz_dea_app_instance : '0' }

  let(:config) do
    AdminUI::Config.load(ccdb_uri:                ccdb_uri,
                         data_file:               data_file,
                         db_uri:                  db_uri,
                         doppler_data_file:       doppler_data_file,
                         doppler_rollup_interval: 1,
                         log_file:                log_file,
                         log_files:               [log_file_displayed],
                         mbus:                    'nats://nats:c1oudc0w@localhost:14222',
                         nats_discovery_timeout:  1,
                         uaadb_uri:               uaadb_uri)
  end

  let(:cc)                 { AdminUI::CC.new(config, logger, true) }
  let(:client)             { AdminUI::CCRestClient.new(config, logger) }
  let(:doppler)            { AdminUI::Doppler.new(config, logger, client, email, true) }
  let(:email)              { AdminUI::EMail.new(config, logger) }
  let(:event_machine_loop) { AdminUI::EventMachineLoop.new(config, logger, true) }
  let(:logger)             { Logger.new(log_file) }
  let(:log_files)          { AdminUI::LogFiles.new(config, logger) }
  let(:nats)               { AdminUI::NATS.new(config, logger, email, true) }
  let(:varz)               { AdminUI::VARZ.new(config, logger, nats, true) }
  let(:stats)              { AdminUI::Stats.new(config, logger, cc, doppler, varz, true) }
  let(:view_models)        { AdminUI::ViewModels.new(config, logger, cc, doppler, log_files, stats, varz, true) }

  def cleanup_files
    Process.wait(Process.spawn({}, "rm -fr #{ccdb_file} #{data_file} #{db_file} #{doppler_data_file} #{log_file} #{log_file_displayed} #{uaadb_file}"))
  end

  before do
    cleanup_files

    File.open(log_file_displayed, 'w') do |file|
      file << log_file_displayed_contents
    end
    File.utime(log_file_displayed_modified, log_file_displayed_modified, log_file_displayed)

    config_stub
    cc_stub(config, false, event_type)
    doppler_stub(application_instance_source)
    nats_stub(application_instance_source)
    varz_stub(application_instance_source)
    view_models_stub(application_instance_source)

    event_machine_loop
  end

  after do
    view_models.shutdown
    stats.shutdown
    varz.shutdown
    nats.shutdown
    doppler.shutdown
    cc.shutdown
    event_machine_loop.shutdown

    view_models.join
    stats.join
    varz.join
    nats.join
    doppler.join
    cc.join
    event_machine_loop.join

    cleanup_files
  end

  context 'Stubbed HTTP' do
    shared_examples 'common view model retrieval' do
      it 'verify view model retrieval' do
        expect(results[:connected]).to eq(true)
        expect(results[:items]).to_not be(nil)

        items = results[:items]

        expected.each do |expected_entry|
          expect(items).to include(expected_entry)
        end
      end
    end

    shared_examples 'common view model retrieval detail' do
      it 'verify view model retrieval detail' do
        expect(expected).to eq(results)
      end
    end

    shared_examples 'application_instances' do
      context 'returns connected application_instances_view_model' do
        let(:event_type) { 'app' }
        let(:results)    { view_models.application_instances }
        let(:expected)   { view_models_application_instances }

        it_behaves_like('common view model retrieval')
      end

      context 'returns connected application_instances_view_model detail' do
        let(:results)  { view_models.application_instance(cc_app[:guid], cc_app_instance_index, varz_application_instance_id) }
        let(:expected) { view_models_application_instances_detail }

        it_behaves_like('common view model retrieval detail')
      end
    end

    context 'varz dea' do
      it_behaves_like('application_instances')
    end

    context 'doppler cell' do
      let(:application_instance_source) { :doppler_cell }
      it_behaves_like('application_instances')
    end

    context 'doppler dea' do
      let(:application_instance_source) { :doppler_dea }
      it_behaves_like('application_instances')
    end

    shared_examples 'applications' do
      context 'returns connected applications_view_model' do
        let(:event_type) { 'app' }
        let(:results)    { view_models.applications }
        let(:expected)   { view_models_applications }

        it_behaves_like('common view model retrieval')
      end

      context 'returns connected applications_view_model detail' do
        let(:results)  { view_models.application(cc_app[:guid]) }
        let(:expected) { view_models_applications_detail }

        it_behaves_like('common view model retrieval detail')
      end
    end

    context 'varz dea' do
      it_behaves_like('applications')
    end

    context 'doppler cell' do
      let(:application_instance_source) { :doppler_cell }
      it_behaves_like('applications')
    end

    context 'doppler dea' do
      let(:application_instance_source) { :doppler_dea }
      it_behaves_like('applications')
    end

    context 'returns connected approvals_view_model' do
      let(:results)    { view_models.approvals }
      let(:expected)   { view_models_approvals }

      it_behaves_like('common view model retrieval')
    end

    context 'returns connected approvals_view_model detail' do
      let(:results)  { view_models.approval(uaa_approval[:user_id], uaa_approval[:client_id], uaa_approval[:scope]) }
      let(:expected) { view_models_approvals_detail }

      it_behaves_like('common view model retrieval detail')
    end

    context 'returns connected buildpacks_view_model' do
      let(:results)    { view_models.buildpacks }
      let(:expected)   { view_models_buildpacks }

      it_behaves_like('common view model retrieval')
    end

    context 'returns connected buildpacks_view_model detail' do
      let(:results)  { view_models.buildpack(cc_buildpack[:guid]) }
      let(:expected) { view_models_buildpacks_detail }

      it_behaves_like('common view model retrieval detail')
    end

    context 'returns connected cells_view_model' do
      let(:application_instance_source) { :doppler_cell }
      let(:results)                     { view_models.cells }
      let(:expected)                    { view_models_cells }

      it_behaves_like('common view model retrieval')
    end

    context 'returns connected cells_view_model detail' do
      let(:application_instance_source) { :doppler_cell }
      let(:results)                     { view_models.cell("#{rep_envelope.ip}:#{rep_envelope.index}") }
      let(:expected)                    { view_models_cells_detail }

      it_behaves_like('common view model retrieval detail')
    end

    context 'returns connected clients_view_model' do
      let(:event_type) { 'service_dashboard_client' }
      let(:results)    { view_models.clients }
      let(:expected)   { view_models_clients }

      it_behaves_like('common view model retrieval')
    end

    context 'returns connected clients_view_model detail' do
      let(:results)  { view_models.client(uaa_client[:client_id]) }
      let(:expected) { view_models_clients_detail }

      it_behaves_like('common view model retrieval detail')
    end

    context 'returns connected cloud_controllers_view_model' do
      let(:results)  { view_models.cloud_controllers }
      let(:expected) { view_models_cloud_controllers }

      it_behaves_like('common view model retrieval')
    end

    context 'returns connected cloud_controllers_view_model detail' do
      let(:results)  { view_models.cloud_controller(nats_cloud_controller['host']) }
      let(:expected) { view_models_cloud_controllers_detail }

      it_behaves_like('common view model retrieval detail')
    end

    context 'returns connected components_view_model' do
      let(:results)  { view_models.components }
      let(:expected) { view_models_components }

      it_behaves_like('common view model retrieval')
    end

    context 'returns connected components_view_model detail' do
      let(:results)  { view_models.component(nats_cloud_controller['host']) }
      let(:expected) { view_models_components_detail }

      it_behaves_like('common view model retrieval detail')
    end

    shared_examples 'deas_view_model' do
      let(:results)  { view_models.deas }
      let(:expected) { view_models_deas }

      it_behaves_like('common view model retrieval')
    end

    shared_examples 'deas_view_model detail' do
      let(:expected) { view_models_deas_detail }
      it_behaves_like('common view model retrieval detail')
    end

    context 'varz deas_view_model' do
      it_behaves_like('deas_view_model')
    end

    context 'varz deas_view_model detail' do
      let(:results) { view_models.dea(nats_dea['host']) }
      it_behaves_like('deas_view_model detail')
    end

    context 'doppler deas_view_model' do
      let(:application_instance_source) { :doppler_dea }
      it_behaves_like('deas_view_model')
    end

    context 'doppler deas_view_model detail' do
      let(:application_instance_source) { :doppler_dea }
      let(:results) { view_models.dea("#{dea_envelope.ip}:#{dea_envelope.index}") }
      it_behaves_like('deas_view_model detail')
    end

    context 'returns connected domains_view_model' do
      let(:results)  { view_models.domains }
      let(:expected) { view_models_domains }

      it_behaves_like('common view model retrieval')
    end

    context 'returns connected domains_view_model detail' do
      let(:results)  { view_models.domain(cc_domain[:guid]) }
      let(:expected) { view_models_domains_detail }

      it_behaves_like('common view model retrieval detail')
    end

    context 'returns connected events_view_model' do
      let(:results)  { view_models.events }
      let(:expected) { view_models_events }

      it_behaves_like('common view model retrieval')
    end

    context 'returns connected events_view_model detail' do
      let(:results)  { view_models.event(cc_event_space[:guid]) }
      let(:expected) { view_models_events_detail }

      it_behaves_like('common view model retrieval detail')
    end

    context 'returns connected feature_flags_view_model' do
      let(:results)    { view_models.feature_flags }
      let(:expected)   { view_models_feature_flags }

      it_behaves_like('common view model retrieval')
    end

    context 'returns connected feature_flags_view_model detail' do
      let(:results)  { view_models.feature_flag(cc_feature_flag[:name]) }
      let(:expected) { view_models_feature_flags_detail }

      it_behaves_like('common view model retrieval detail')
    end

    context 'returns connected gateways_view_model' do
      let(:results)  { view_models.gateways }
      let(:expected) { view_models_gateways }

      it_behaves_like('common view model retrieval')
    end

    context 'returns connected gateways_view_model detail' do
      let(:results)  { view_models.gateway(nats_provisioner['type'].sub('-Provisioner', '')) }
      let(:expected) { view_models_gateways_detail }

      it_behaves_like('common view model retrieval detail')
    end

    context 'returns connected group_members_view_model' do
      let(:results)  { view_models.group_members }
      let(:expected) { view_models_group_members }

      it_behaves_like('common view model retrieval')
    end

    context 'returns connected group_members_view_model detail' do
      let(:results)  { view_models.group_member(uaa_group[:id], uaa_user[:id]) }
      let(:expected) { view_models_group_members_detail }

      it_behaves_like('common view model retrieval detail')
    end

    context 'returns connected groups_view_model' do
      let(:results)  { view_models.groups }
      let(:expected) { view_models_groups }

      it_behaves_like('common view model retrieval')
    end

    context 'returns connected groups_view_model detail' do
      let(:results)  { view_models.group(uaa_group[:id]) }
      let(:expected) { view_models_groups_detail }

      it_behaves_like('common view model retrieval detail')
    end

    shared_examples 'health_managers_view_model' do
      let(:results)  { view_models.health_managers }
      let(:expected) { view_models_health_managers }

      it_behaves_like('common view model retrieval')
    end

    shared_examples 'health_managers_view_model detail' do
      let(:expected) { view_models_health_managers_detail }
      it_behaves_like('common view model retrieval detail')
    end

    context 'varz health_managers_view_model' do
      it_behaves_like('health_managers_view_model')
    end

    context 'varz health_managers_view_model detail' do
      let(:results) { view_models.health_manager(nats_health_manager['host']) }
      it_behaves_like('health_managers_view_model detail')
    end

    context 'doppler health_managers_view_model' do
      let(:application_instance_source) { :doppler_dea }
      it_behaves_like('health_managers_view_model')
    end

    context 'doppler health_managers_view_model detail' do
      let(:application_instance_source) { :doppler_dea }
      let(:results) { view_models.health_manager("#{analyzer_envelope.ip}:#{analyzer_envelope.index}") }
      it_behaves_like('health_managers_view_model detail')
    end

    context 'returns connected identity_providers_view_model' do
      let(:results)  { view_models.identity_providers }
      let(:expected) { view_models_identity_providers }

      it_behaves_like('common view model retrieval')
    end

    context 'returns connected identity_providers_view_model detail' do
      let(:results)  { view_models.identity_provider(uaa_identity_provider[:id]) }
      let(:expected) { view_models_identity_providers_detail }

      it_behaves_like('common view model retrieval detail')
    end

    context 'returns connected identity_zones_view_model' do
      let(:results)  { view_models.identity_zones }
      let(:expected) { view_models_identity_zones }

      it_behaves_like('common view model retrieval')
    end

    context 'returns connected identity_zones_view_model detail' do
      let(:results)  { view_models.identity_zone(uaa_identity_zone[:id]) }
      let(:expected) { view_models_identity_zones_detail }

      it_behaves_like('common view model retrieval detail')
    end

    context 'returns connected logs_view_model' do
      let(:results)                                  { view_models.logs }
      let(:log_file_displayed_contents_length)       { log_file_displayed_contents.length }
      let(:log_file_displayed_modified_milliseconds) { AdminUI::Utils.time_in_milliseconds(log_file_displayed_modified) }
      let(:expected)                                 { view_models_logs(log_file_displayed, log_file_displayed_contents_length, log_file_displayed_modified_milliseconds) }

      it_behaves_like('common view model retrieval')
    end

    shared_examples 'organizations' do
      context 'returns connected organizations_view_model' do
        let(:results)  { view_models.organizations }
        let(:expected) { view_models_organizations }

        it_behaves_like('common view model retrieval')
      end

      context 'returns connected organizations_view_model detail' do
        let(:results)  { view_models.organization(cc_organization[:guid]) }
        let(:expected) { view_models_organizations_detail }

        it_behaves_like('common view model retrieval detail')
      end
    end

    context 'varz dea' do
      it_behaves_like('organizations')
    end

    context 'doppler cell' do
      let(:application_instance_source) { :doppler_cell }
      it_behaves_like('organizations')
    end

    context 'doppler dea' do
      let(:application_instance_source) { :doppler_dea }
      it_behaves_like('organizations')
    end

    context 'returns connected organization_roles_view_model' do
      let(:results)  { view_models.organization_roles }
      let(:expected) { view_models_organization_roles }

      it_behaves_like('common view model retrieval')
    end

    context 'returns connected organization_roles_view_model detail' do
      let(:results)  { view_models.organization_role(cc_organization[:guid], 'auditors', cc_user[:guid]) }
      let(:expected) { view_models_organization_roles_detail }

      it_behaves_like('common view model retrieval detail')
    end

    context 'returns connected quotas_view_model' do
      let(:results)  { view_models.quotas }
      let(:expected) { view_models_quotas }

      it_behaves_like('common view model retrieval')
    end

    context 'returns connected quotas_view_model detail' do
      let(:results)  { view_models.quota(cc_quota_definition[:guid]) }
      let(:expected) { view_models_quotas_detail }

      it_behaves_like('common view model retrieval detail')
    end

    shared_examples 'routers_view_model' do
      let(:results)  { view_models.routers }
      let(:expected) { view_models_routers }

      it_behaves_like('common view model retrieval')
    end

    shared_examples 'routers_view_model detail' do
      let(:expected) { view_models_routers_detail }
      it_behaves_like('common view model retrieval detail')
    end

    context 'varz routers_view_model' do
      it_behaves_like('routers_view_model')
    end

    context 'varz routers_view_model detail' do
      let(:results) { view_models.router(nats_router['host']) }
      it_behaves_like('routers_view_model detail')
    end

    context 'doppler routers_view_model' do
      let(:application_instance_source) { :doppler_dea }
      it_behaves_like('routers_view_model')
    end

    context 'doppler routers_view_model detail' do
      let(:application_instance_source) { :doppler_dea }
      let(:results) { view_models.router("#{gorouter_envelope.ip}:#{gorouter_envelope.index}") }
      it_behaves_like('routers_view_model detail')
    end

    context 'returns connected route_mappings_view_model' do
      let(:results)    { view_models.route_mappings }
      let(:expected)   { view_models_route_mappings }

      it_behaves_like('common view model retrieval')
    end

    context 'returns connected route_mappings_view_model detail' do
      let(:results)  { view_models.route_mapping(cc_app_route[:guid]) }
      let(:expected) { view_models_route_mappings_detail }

      it_behaves_like('common view model retrieval detail')
    end

    context 'returns connected routes_view_model' do
      let(:event_type) { 'route' }
      let(:results)    { view_models.routes }
      let(:expected)   { view_models_routes }

      it_behaves_like('common view model retrieval')
    end

    context 'returns connected routes_view_model detail' do
      let(:results)  { view_models.route(cc_route[:guid]) }
      let(:expected) { view_models_routes_detail }

      it_behaves_like('common view model retrieval detail')
    end

    context 'returns connected security_groups_spaces_view_model' do
      let(:results)    { view_models.security_groups_spaces }
      let(:expected)   { view_models_security_groups_spaces }

      it_behaves_like('common view model retrieval')
    end

    context 'returns connected security_groups_spaces_view_model detail' do
      let(:results)  { view_models.security_group_space(cc_security_group[:guid], cc_space[:guid]) }
      let(:expected) { view_models_security_groups_spaces_detail }

      it_behaves_like('common view model retrieval detail')
    end

    context 'returns connected security_groups_view_model' do
      let(:results)    { view_models.security_groups }
      let(:expected)   { view_models_security_groups }

      it_behaves_like('common view model retrieval')
    end

    context 'returns connected security_groups_view_model detail' do
      let(:results)  { view_models.security_group(cc_security_group[:guid]) }
      let(:expected) { view_models_security_groups_detail }

      it_behaves_like('common view model retrieval detail')
    end

    context 'returns connected service_bindings_view_model' do
      let(:event_type) { 'service_binding' }
      let(:results)    { view_models.service_bindings }
      let(:expected)   { view_models_service_bindings }

      it_behaves_like('common view model retrieval')
    end

    context 'returns connected service_bindings_view_model detail' do
      let(:results)  { view_models.service_binding(cc_service_binding[:guid]) }
      let(:expected) { view_models_service_bindings_detail }

      it_behaves_like('common view model retrieval detail')
    end

    context 'returns connected service_brokers_view_model' do
      let(:event_type) { 'service_broker' }
      let(:results)    { view_models.service_brokers }
      let(:expected)   { view_models_service_brokers }

      it_behaves_like('common view model retrieval')
    end

    context 'returns connected service_brokers_view_model detail' do
      let(:results)  { view_models.service_broker(cc_service_broker[:guid]) }
      let(:expected) { view_models_service_brokers_detail }

      it_behaves_like('common view model retrieval detail')
    end

    context 'returns connected service_instances_view_model' do
      let(:event_type) { 'service_instance' }
      let(:results)    { view_models.service_instances }
      let(:expected)   { view_models_service_instances }

      it_behaves_like('common view model retrieval')
    end

    context 'returns connected service_instances_view_model detail' do
      let(:results)  { view_models.service_instance(cc_service_instance[:guid]) }
      let(:expected) { view_models_service_instances_detail }

      it_behaves_like('common view model retrieval detail')
    end

    context 'returns connected service_keys_view_model' do
      let(:event_type) { 'service_key' }
      let(:results)    { view_models.service_keys }
      let(:expected)   { view_models_service_keys }

      it_behaves_like('common view model retrieval')
    end

    context 'returns connected service_keys_view_model detail' do
      let(:results)  { view_models.service_key(cc_service_key[:guid]) }
      let(:expected) { view_models_service_keys_detail }

      it_behaves_like('common view model retrieval detail')
    end

    context 'returns connected service_plans_view_model' do
      let(:event_type) { 'service_plan' }
      let(:results)    { view_models.service_plans }
      let(:expected)   { view_models_service_plans }

      it_behaves_like('common view model retrieval')
    end

    context 'returns connected service_plans_view_model detail' do
      let(:results)  { view_models.service_plan(cc_service_plan[:guid]) }
      let(:expected) { view_models_service_plans_detail }

      it_behaves_like('common view model retrieval detail')
    end

    context 'returns connected service_plan_visibilities_view_model' do
      let(:event_type) { 'service_plan_visibility' }
      let(:results)    { view_models.service_plan_visibilities }
      let(:expected)   { view_models_service_plan_visibilities }

      it_behaves_like('common view model retrieval')
    end

    context 'returns connected service_plan_visibilities_view_model detail' do
      let(:results)  { view_models.service_plan_visibility(cc_service_plan_visibility[:guid]) }
      let(:expected) { view_models_service_plan_visibilities_detail }

      it_behaves_like('common view model retrieval detail')
    end

    context 'returns connected services_view_model' do
      let(:event_type) { 'service' }
      let(:results)    { view_models.services }
      let(:expected)   { view_models_services }

      it_behaves_like('common view model retrieval')
    end

    context 'returns connected services_view_model detail' do
      let(:results)  { view_models.service(cc_service[:guid]) }
      let(:expected) { view_models_services_detail }

      it_behaves_like('common view model retrieval detail')
    end

    context 'returns connected space_quotas_view_model' do
      let(:results)  { view_models.space_quotas }
      let(:expected) { view_models_space_quotas }

      it_behaves_like('common view model retrieval')
    end

    context 'returns connected space_quotas_view_model detail' do
      let(:results)  { view_models.space_quota(cc_space_quota_definition[:guid]) }
      let(:expected) { view_models_space_quotas_detail }

      it_behaves_like('common view model retrieval detail')
    end

    context 'returns connected space_roles_view_model' do
      let(:results)  { view_models.space_roles }
      let(:expected) { view_models_space_roles }

      it_behaves_like('common view model retrieval')
    end

    context 'returns connected space_roles_view_model detail' do
      let(:results)  { view_models.space_role(cc_space[:guid], 'auditors', cc_user[:guid]) }
      let(:expected) { view_models_space_roles_detail }

      it_behaves_like('common view model retrieval detail')
    end

    shared_examples 'spaces' do
      context 'returns connected spaces_view_model' do
        let(:results)  { view_models.spaces }
        let(:expected) { view_models_spaces }

        it_behaves_like('common view model retrieval')
      end

      context 'returns connected spaces_view_model detail' do
        let(:results)  { view_models.space(cc_space[:guid]) }
        let(:expected) { view_models_spaces_detail }

        it_behaves_like('common view model retrieval detail')
      end
    end

    context 'varz dea' do
      it_behaves_like('spaces')
    end

    context 'doppler cell' do
      let(:application_instance_source) { :doppler_cell }
      it_behaves_like('spaces')
    end

    context 'doppler dea' do
      let(:application_instance_source) { :doppler_dea }
      it_behaves_like('spaces')
    end

    context 'returns connected stacks_view_model' do
      let(:results)  { view_models.stacks }
      let(:expected) { view_models_stacks }

      it_behaves_like('common view model retrieval')
    end

    context 'returns connected stacks_view_model detail' do
      let(:results)  { view_models.stack(cc_stack[:guid]) }
      let(:expected) { view_models_stacks_detail }

      it_behaves_like('common view model retrieval detail')
    end

    shared_examples 'stats_view_model' do
      let(:results)   { view_models.stats }
      let(:timestamp) { results[:items][0][9][:timestamp] } # We have to copy the timestamp from the result since it is variable
      let(:expected)  { view_models_stats(timestamp) }

      it_behaves_like('common view model retrieval')
    end

    context 'varz dea' do
      it_behaves_like('stats_view_model')
    end

    context 'doppler cell' do
      let(:application_instance_source) { :doppler_cell }
      it_behaves_like('stats_view_model')
    end

    context 'doppler dea' do
      let(:application_instance_source) { :doppler_dea }
      it_behaves_like('stats_view_model')
    end

    context 'returns connected users_view_model' do
      let(:results)  { view_models.users }
      let(:expected) { view_models_users }

      it_behaves_like('common view model retrieval')
    end

    context 'returns connected users_view_model detail' do
      let(:results)  { view_models.user(cc_user[:guid]) }
      let(:expected) { view_models_users_detail }

      it_behaves_like('common view model retrieval detail')
    end
  end
end
