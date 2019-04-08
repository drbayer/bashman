
class Profile::Shell < JSONable
    include Bashman

    CONFIG = self.get_config('shell')
    BASEPATH = CONFIG.key?("basepath") ? File.expand_path(CONFIG["basepath"]) : File.expand_path("~/")
    BLOCKSIZE = 1024

    attr_reader :shell
    attr_reader :dotfiles

    def initialize
        @shell = self.get_current
    end

    def get_dotfiles
        exc = []
        inc = []

        if CONFIG.include?('exclude')
            exc = CONFIG['exclude'].split(',').map {|x| x.strip}
        end

        if CONFIG.include?('include')
            inc = CONFIG['include'].split(',').map {|x| x.strip}
        else
            inc = ["\.[a-zA-Z0-9-_]*"]
        end

        files = self.add_includes(inc)
        files = self.remove_excludes(exc, files)
        files.delete_if {|f| /\.bashman\/profiles/ =~ f}

        @dotfiles = files
    end

    def save_dotfiles(tarfile, timestamp = nil, overwrite = false)
        require 'fileutils'
        
        savefile = File.expand_path(tarfile)
        
        if File.exists?(savefile)
            if not overwrite
                timestamp = File.mtime(savefile).to_i if timestamp.nil?
                bakfile = "#{savefile}.#{timestamp}"
                File.delete(bakfile) if File.exists?(bakfile)
                FileUtils.mv(savefile, bakfile)
            end
        end

        begin
            self.tar_gz(BASEPATH, savefile, *@dotfiles)
        rescue => e
            puts "Error saving dotfiles:  #{e.message}"
            puts e.backtrace
            File.delete(savefile) if File.exists?(savefile)
            if not bakfile.nil? and File.exists?(bakfile)
                FileUtils.mv(bakfile, savefile)
            end
            return 1
        end

    end
    protected

    def get_current
        ENV['SHELL']
    end

    def remove_excludes(excludes, files)
        excludes.each do |e|
            e.gsub!('.', '\.')
            e.gsub!('*', '.*')
            files.delete_if {|f| /#{e}/ =~ f}
        end
        files
    end

    def add_includes(includes)
        files = []
        includes.each do |i|
            files.concat Dir.glob(i, base: BASEPATH)
        end

        files.dup.each do |f|
            if File.directory?("#{BASEPATH}/#{f}")
                files.concat Dir.glob("#{f}/**/*", base: BASEPATH)
            end
        end
       files
    end

    def tar_gz(path, tarfile, *src)
        require 'rubygems/package'
        require 'find'
        require 'pathname'

        basepath = Pathname.new(BASEPATH)
        path = Pathname.new(path)

        raise ArgumentError, "Path #{path} should be an absolute path" unless path.absolute?
        raise ArgumentError, "Path #{path} should be a directory" unless File.directory?(path)
        raise ArgumentError, "No files/directories found to tar" if !src or src.length == 0

        src.each {|p| p.sub!(/^/, "#{basepath.to_s}/")}
        File.open(tarfile, "wb") do |tf|
            Zlib::GzipWriter.wrap(tf) do |gz|
                Gem::Package::TarWriter.new(gz) do |tar|
                    src.each do |f|
                        next if not File.file?(f)
                        file = Pathname.new(f)
                        relpath = file.relative_path_from(basepath).to_s
                        mode = File.stat(f).mode
                        size = File.stat(f).size
                        if File.directory?(f)
                            tar.mkdir(relpath, mode)
                        else
                            tar.add_file_simple(relpath, mode, size) do |tio|
                                File.open(f, "rb") do |rio|
                                    while buffer = rio.read(BLOCKSIZE)
                                        tio.write(buffer)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

end
