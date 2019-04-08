
class Profile::HomeBrew < JSONable

    include Bashman

    attr_reader :casks
    attr_reader :formulae

    def get_installed
        @installed = self.installed? if @installed.nil?

        if @installed
            @casks = self.get_casks
            @formulae = self.get_formulae
        end
    end

    def installed?
        path = Profile::HomeBrew.which('brew')
        @installed = path.empty? ? false : true
        @installed
    end

    protected

    def get_casks
        %x(brew cask list).split("\n")
    end

    def get_formulae
        %x(brew list).split("\n")
    end

end

