# What is the DOCS.pkd file?

The PikaDoc project proposes adding a file called `DOCS.pkd` to the root of your repositories to make your reference documentation more discoverable. This is a simple, auto-generated text file that can be read without specialized reader software. It offers relevant information for all functions, modules, etc. in your project. To find out more about our reasoning, keep reading.

## Why we need offline documentation

As long as open source software has been distributed, we've had the wonderful convention of including a README file explaining the contents of a distribution. While these days those files are more fully-featured, including dynamic elements such as images and other rich media, one thing hasn't changed: the role of the README-file as the first source of information when encountering new software.

README files (and other text files) can be an incredibly useful form of documentation when well-written and maintained. Indeed, many open source projects could benefit from relying more on this type of documentation. What we tend to get instead is a variety of documentation portals coming in different shapes and sizes. This is a reasonable solution. Even a medium-size open source project can have hundreds to thousands of symbols that need to be systematically documented, hardly a job that can be done by hand. Documentation also needs to be discoverable by search engines as this is what we've grown accustomed to answer our technical questions.

Still, in the recent years many developers are finding that search engines are doing an increasingly poor job in returning relevant results to their questions. Finding official documentation can be a pain, especially when your project depends on an outdated package. Ideally we'd like to package our software with a file that is capable of providing answers even when the project homepage is unavailable. This is where "DOCS.pkd" comes in.

`pkd` is a structured documentation format that exists primarily to answer one question: *what is this?* When you see an unfamiliar function, class or some other reference, answering this question should be near instant - it should not require minutes of navigating through search engines and documentation portals. While you're doing this, you shouldn't be exposed to ads, sidenotes and other forms of digital noise breaking your flow. You should only see the answer you're looking for.

While packaging documentation with software is hardly a new idea, what's novel about pkd is that it is a structured data format. Reading a pkd-file is as simple as typing `less DOCS.pkd`, yet it can be used to answer advanced queries that are beyond the capabilities of most documentation portals. For example:

- list all modules with "parse" in their name
- list all classes with a property called "name"
- list all functions that return an instance of the class "Foo"

Despite these advanced features, pkd doctables are formatted in simple, human-readable YAML. For small projects, this file is uncomplicated enough to write by hand, yet it easily scales up to thousands, even tens of thousands of symbols. [Click here](</help/The .pkd file format.md>) for more information on the file format.

Much like the README-file explains how to use a software distribution, the DOCS.pkd explains what it contains. It lists every public-facing function, class, method and what-have-you, explaining briefly or in-detail what it's all about. Ideally it's generated directly from the project sources using a documentation generator, making sure it stays up to date at all times. Essentially, the pkd file acts as a portable reference guide, making that type of documentation accessible even for small-scale projects that have no resources for maintaining their own documentation portal. As such, the point is not to stretch the already meager project resources even thinner with a new format, but simply to make the already existing documentation more available to end users.

## How do I generate a pkd-file?

Install the [PikaDoc CLI](README.md) to find out more about our currently available documentation sources. If your tech stack isn't supported yet, writing a pkd-generator can be quite convenient, if your documentation format supports structured output. For a simple example, you can take a look at our `src:nushell` generator.
