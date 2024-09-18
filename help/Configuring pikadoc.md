# Configuring pikadoc

For general configuration, pikadoc uses the standard nushell configuration file. You can find it by it typing `ls ($env.PKD_CONFIG_HOME|path join 'config.nu')`.

For pikadoc specific configuration, you can examine `$env.PKD_CONFIG`. The values ending with `command` can be overwritten to change how pikadoc interacts with dependencies such as programming language interpreters and pagers. To find out more about a specific command, you can type `view source $env.PKD_CONFIG.<command_name>`.

To persistently change these values, you can use the `pikadocrc.nu`-file. To get started, you can type:

```nu
cp -n ($env.PKD_HOME|path join 'pikadocrc.example.nu') ($env.PKD_CONFIG_HOME|path join 'pikadocrc.nu')
```

If pikadoc finds a file called `pikadocrc.nu` in your config directory, it's automatically sourced into the shell environment. In addition to setting configuration values, it allows you to create reusable functions that persist between sessions. This can be useful for customizing your workflow with shortcuts for frequently used commands.
