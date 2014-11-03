# Annlat

This gem contains all used in Learnleague platform and testengine libraries.

## Installation

Add this line to your application's Gemfile (that is already don in CDK):

    gem 'annlat', git: 'https://github.com/fwpnetwork/annlat'

And then execute:

    $ bundle

## Usage

Example of usage: https://gist.github.com/randomlogin/7e019b8f6bb32b679810

Addition of the object is the same as before:

    r = AnnLat.new
    r.add("Hello world!")
    r.add("The new string")
    
Each call of `add` will create a new 'sentence' that will be displayed on a new line or in another bubble if it is a hint.
`add` now returns AnnLat objects, so there is no need to explicitly return `r` after you added something to it at the end of method definition.

### Options

There are two types of options now: options for the sentence as single whole and for each word.
To add options for the whole sentence you can pass them as a hash as first argument of `add`.

    r.add({style: 'color:red'}, 'This sentence is displayed in red')
    
Now each 'word' may have options too. For example, you can empasize or change color of some words:

    r.add('This last word of this sentence is ', {object: 'cyan', options: {style: 'color:cyan'}})
    
Syntax for word-options: a hash with key-value pair for object and options.
For now options are treated as html options for tags, but with time we can add some styles, so appearance of the concept could be dramatically adjusted.
You can explicitly pass an html tag you want to use, see Hint paragraph below.

### Hints

Adding hints:

    r.add_hint("This is a hint. ", "This sentence is in the same bubble as the previous.")
    r.add_hint("This is another bubble.", " However it's possible to create a line break here", {object: 'so this is in the same bubble, but on the new line', options: {tag: :p}})
    
The latter hint will be displayed just as you expect it.
    
### Multiple answer questions.

Now you can just pass options for the sentence indicating that it's an answer variant. (Be carefull, now it's symbol :multiple, not :multiple_answer)

    r.add({:multiple => true}, 'It\'s even possible to add an image to the variant of multiple-answer question.')
    r.add({:multiple => true}, {object: @img, options:{width: '30%'}})
    
## Contributing

1. Fork it ( https://github.com/fwpnetwork/annlat/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

    
    
    
