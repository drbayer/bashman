
module Bashman
    require "bashman/version"

    CONFIG_PATH = File.expand_path('~/.bashman')
    CONFIG = File.expand_path("#{CONFIG_PATH}/config")

    FileUtils.mkdir_p(CONFIG_PATH) if not Dir.exists?(CONFIG_PATH)
    FileUtils.touch(CONFIG) if not File.exists?(CONFIG)

    def self.included(base)
        base.extend(ClassMethods)
    end

    # make the following functions available in every class
    module ClassMethods
        def which(binary)
            ret = ''
            possibles = ENV["PATH"].split(File::PATH_SEPARATOR)
            possibles.map {|p| File.join(p, binary)}.find {|p| ret = p if File.executable?(p)}
            ret
        end

        def get_config(section)
            require 'parseconfig'

            fullconfig = ParseConfig.new(CONFIG)
            config = {}
            config = fullconfig[section] if fullconfig.get_params.include?(section)
            config
        end
    end

    def Bashman.version
        puts Bashman::VERSION
    end

end


class JSONable
    require 'json'

    def to_hash
        hash = {}
        self.instance_variables.each do |var|
            hash[var] = self.instance_variable_get(var)
        end
        hash
    end

    def to_json
        hash = self.to_hash
        hash.to_json
    end

    def from_json!(string)
        JSON.load(string).each do |var, val|
            self.instance_variable_set(var, val)
        end
    end
end


# this is me learning how to write ruby gems
# no idea why, but if I don't put the Profile class
# in this file things break in spectacular ways

class Profile < JSONable
    require "bashman/homebrew"
    require "bashman/shell"

    include Bashman

    attr_reader :homebrew
    attr_reader :shell
    attr_reader :name

    def initialize(profile_name = 'default')
        @name = profile_name
    end

    def add_homebrew(verbose = false)
        @homebrew = Profile::HomeBrew.new
        puts "Looking for Homebrew" if verbose
        if @homebrew.installed?
            puts "Homebrew executable found" if verbose
            puts "Getting installed homebrew packages and casks"
            @homebrew.get_installed
            if verbose
                puts "Found formulae:"
                @homebrew.formulae.each {|f| puts "  #{f}"}
                puts "Found casks:"
                @homebrew.casks.each {|c| puts "  #{c}"}
            end
        else
            puts "Homebrew executable not found"
        end
    end

    def add_shell(verbose = false)
        @shell = Profile::Shell.new
        puts "Gathering shell components" if verbose
        puts "Found shell #{@shell.shell}" if verbose
        puts "Getting files to save" if verbose
        @shell.get_dotfiles
        if verbose
            puts "Found shell files to save:"
            @shell.dotfiles.each {|d| puts "  #{d}"}
        end
    end

    def save(dir = '~/.bashman/profiles', overwrite = false, verbose = false)
        dir = File.expand_path(dir)
        FileUtils.mkdir_p(dir) if not Dir.exists?(dir)

        # get the current unix timestamp for later use when 
        # creating new saved profiles
        @timestamp = Time.now.to_i

        # get timestamp from manifest in the event we need to back up files
        manifest = "#{dir}/#{name}.json"
        puts "Saving manifest file #{manifest}" if verbose
        timestamp = nil
        if not overwrite
            if File.exists?(manifest)
                begin 
                    timestamp = JSON.parse(File.read(manifest))['@timestamp']
                rescue
                    timestamp = File.mtime(manifest).to_i if timestamp.nil?
                end
                FileUtils.mv(manifest, "#{manifest}.#{timestamp}")
            end
        end

        # now save shell files and write manifest
        if instance_variable_defined?("@shell")
            shell = @shell.to_hash 
            @shell.save_dotfiles("#{dir}/#{name}.tar.gz", timestamp, overwrite)
            @shell = shell
        end

        if instance_variable_defined?("@homebrew")
            homebrew = @homebrew.to_hash 
            @homebrew = homebrew
        end

        manifest_content = self.to_json
        File.open(manifest, 'w') do |file|
            file.write(manifest_content)
        end

    end

end


