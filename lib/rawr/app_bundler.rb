require 'fileutils'
require 'rawr/bundler'
require 'rawr/bundler_template'

# See http://developer.apple.com/documentation/Java/Reference/Java_InfoplistRef/Articles/JavaDictionaryInfo.plistKeys.html for details

module Rawr
  class AppBundler < Bundler  
    include FileUtils

    def deploy(options)
      @project_name = options.project_name
      @classpath = options.classpath
      @main_java_class = options.main_java_file
      @built_jar_path = options.jar_output_dir
      @working_directory = options.mac_plist_working_directory
      
      @mac_path = options.osx_output_dir
      @mac_app_path = "#{@mac_path}/#{@project_name}.app"
      @java_app_deploy_path = "#{@mac_app_path}/Contents/Resources/Java"
      @target_jvm_version = options.target_jvm_version
      @jvm_arguments = options.jvm_arguments || ""
      @java_library_path = options.java_library_path
      
      @mac_icon_default = options.mac_icon_path.nil?
      @mac_icon_path = options.mac_icon_path ||= 'GenericJavaApp.icns'
      
      puts "Creating OSX application at #{@mac_app_path}"
      
      create_clean_deployment_directory_structure(@mac_path, @mac_app_path)
      copy_deployment_to @java_app_deploy_path
      generate_info_plist
      generate_pkg_info
      deploy_info_plist
      deploy_artwork
      deploy_app_stub
    end

    def create_clean_deployment_directory_structure(mac_path, mac_app_path)
      rm_rf mac_path if File.exists? mac_path

      mkdir_p mac_path
      mkdir_p mac_app_path
      mkdir_p "#{mac_app_path}/Contents"
      mkdir_p "#{mac_app_path}/Contents/MacOS"
      mkdir_p "#{mac_app_path}/Contents/Resources"
    end

    def deploy_artwork
      if @mac_icon_default
        #give us a default icon, which Rawr provides. This comes from the default icon in the Jar Bundler for OSX.
        cp "#{File.expand_path(File.dirname(__FILE__))}/../../data/GenericJavaApp.icns", "#{@mac_app_path}/Contents/Resources"
      else
        cp @mac_icon_path, "#{@mac_app_path}/Contents/Resources"
      end
    end
    
    def deploy_app_stub
      stub_destination = "#{@mac_app_path}/Contents/MacOS"
      stub_file = "JavaApplicationStub"
      
      cp "#{File.expand_path(File.dirname(__FILE__))}/../../data/#{stub_file}", stub_destination
      chmod 0755, "#{stub_destination}/#{stub_file}"
    end

    def generate_pkg_info
      File.open "#{@mac_app_path}/Contents/PkgInfo", "w" do |file|
        file << "APPL????"
      end
    end

    def deploy_info_plist
      cp "Info.plist", "#{@mac_app_path}/Contents/"
    end
    
    def generate_info_plist
      return if Rawr::Configuration.current_config.mac_do_not_generate_plist
      mac_icon_filename = @mac_icon_path.sub(File.dirname(@mac_icon_path) + '/', '')

      File.open "Info.plist", 'w' do |file|
        file << BundlerTemplate.find('app_bundler', 'Info.plist').result(binding)
      end
    end
  end
end