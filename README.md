# Bashman

A Ruby gem and executable for *nix profile backup.

## Usage

This gem includes the `bashman` executable for managing profiles. 

```
$ bashman -h
Usage: bashman [OPTIONS]

    -a, --apply                      Apply saved profile
    -i, --items homebrew,shell       Shell components to apply or save. Defaults to 'all'.
    -p, --profile PROFILE            Profile name. Set to 'default' if not specified.
    -s, --save                       Save profile settings.
    -v, --verbose                    Turn on verbose messages.
    -V, --version                    Show version
    -y, --yes                        Do not ask for confirmation
    -h, --help                       Show this help message
 ```

For script development, the gem provides the following classes:
|Class Name|Purpose|
|---|---|
|Profile|Overall user profile container|
|Profile::HomeBrew|Homebrew information for Mac users|
|Profile::Shell|General shell items like .profile, .bashrc, etc.|

## Configuration
Bashman looks for the `~/.bashman/config` file for configuration information. At present the only configuration is for `[shell]` and controls which shell files to include/exclude from the profile backup. Useful for limiting backup to desired configuration items and omitting sensitive and/or unnecessary components like SSH keys.

```
[shell]
    exclude = .vim/bundle
    include = .bash*, .git* .irb*, .iterm2*, .profile*, .vim*
```

## Development

This is still in very early stages of development and is likely to be buggy. 

This was built as a learning experience that results in something useful at least to me. Because of this I'm sure there is a lot missing that should probably be included, not the least of which would be code tests. If all goes well that will be included in the not too distant future. 

There are plans for adding more functionality, including applying saved profiles back to the current user. 

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/drbayer/bashman.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
