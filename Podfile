platform :ios, '6.0'

# RestKit
pod 'RestKit', '~> 0.23.1'
pod 'RestKit/Testing', '~> 0.23.1'
pod 'RestKit/Search', '~> 0.23.1'

# UIAlertView and UIActionSheet with blocks
pod 'OHActionSheet'
pod 'OHAlertView'

# Add acknowledgements
post_install do | installer |
  require 'fileutils'
  FileUtils.cp_r('Pods/Pods-Acknowledgements.plist', 'QUe/Settings.bundle/Acknowledgements.plist', :remove_destination => true)
end
