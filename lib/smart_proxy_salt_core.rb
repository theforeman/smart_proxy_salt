require 'foreman_tasks_core'
require 'foreman_remote_execution_core'

module SmartProxySaltCore
  # extend ForemanTasksCore::SettingsLoader
  # register_settings(:salt)

  if ForemanTasksCore.dynflow_present?
    require 'smart_proxy_salt_core/salt_runner'
    require 'smart_proxy_salt_core/salt_task_launcher'

    if defined?(SmartProxyDynflowCore)
      SmartProxyDynflowCore::TaskLauncherRegistry.register('salt', SaltTaskLauncher)
    end
  end
end
