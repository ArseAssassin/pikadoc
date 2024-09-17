# Documentation libraries

Often when working on a project, we need to reference between multiple documentation sources to find the information we need. `doc lib` provides us with a convenient way to do that.

```nu
# By default, our library is empty
doc lib index
> ╭────────────╮
> │ empty list │
> ╰────────────╯

# Let's add some doctables to our library
doc s use html
doc lib add

# We can also pass a closure to `doc lib add`
doc lib add { doc s use css }

doc lib index
> ╭───┬───────╮
> │ 0 │ HTML~ │
> │ 1 │ CSS~  │
> ╰───┴───────╯

# We can now quickly change doctables
doc lib use css
> 1006 symbols found
> Using doctable CSS~

doc lib use 0
> 337 symbols found
> Using doctable HTML~

# We can quickly search any doctable in our library
doc lib css flex

# We can also query all our documentation sources at the same time
doc lib query {doc link}

# Libraries can easily be saved for future use
mkdir .pikadocs
doc lib save .pikadocs/library.pkl

# Use the library in a new session
doc lib load .pikadocs/library.pkl

# To autoload project libraries, see `pikadocrc.example.nu`
cat ($env.PKD_HOME|path join 'pikadocrc.example.nu')
```
