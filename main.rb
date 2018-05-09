require 'fast_stemmer'

 def snippet(html,query)
    return_html = []
    queue = []
    least = ""
    started = false
    hash_quey = Hash[query.collect { |v| [v, v] }]

    html.split().each do |word|

      stemmed_word = stemmer(word.downcase)
      downcased_word = word.downcase
      if downcased_word == queue[0]
        len = queue.size
        least = queue.join(' ')
        while queue[0] == downcased_word do
          queue.pop
        end
      end
          
      if hash_quey[stemmed_word] == stemmed_word
        queue << downcased_word
        started = true
      end

      if downcased_word != queue[queue.size-1] and started
        queue << word.downcase
      end
    end
    
    least = queue.join(' ') if least.length == 0

    least.split().each do |word|
      stemmed_word = stemmer(word)
      if hash_quey[stemmed_word] == stemmed_word
        return_html << '<b>' + word +'</b>'
      else
        return_html << word
      end
    end

    return_html.join(' ')

  end

  def stemmer(word)
    Stemmer::stem_word(word)
  end

str = """
README.md Fluent Swift Animations made Easy Installation Add the following to your Podfile and run pod install pod 'Fluent',
'~> 0.1' or add the following to your Cartfile and run carthage update github 'matthewcheok/Fluent' or clone as a git submodule,
or just copy files in the Fluent folder into your project. Using Fluent Fluent makes writing animations declarative and chainable.
boxView .animate(0.5) .rotate(0.5) .scale(2) .backgroundColor(.blueColor()) .waitThenAnimate(0.5) .scale(1) .backgroundColor(.redColor())
Simply call one of the animation methods, of which only duration is required: animate(duration: NSTimeInterval, velocity: CGFloat , damping:
CGFloat, options: UIViewAnimationOptions) waitThenAnimate(duration: NSTimeInterval, velocity: CGFloat , damping: CGFloat, options:
UIViewAnimationOptions) All common properties on UIView are supported: scale(factor: CGFloat) translate(x: CGFloat, y: CGFloat)
rotate(cycles: CGFloat) backgroundColor(color: UIColor) alpha(alpha: CGFloat) frame(frame: CGRect) bounds(bounds: CGRect) 
center(center: CGPoint) There are also relative versions of the transforms: scaleBy(factor: CGFloat) translateBy(x: CGFloat, y: CGFloat) 
rotateBy(cycles: CGFloat) You may not mix absolute and relative transformations in the same animation. Using transforms The order of the 
transformations are important! To reverse the following: boxView .animate(1) .translateBy(50, 50) .rotateBy(0.5) .scaleBy(2) 
.backgroundColor(.blueColor()) .alpha(0.7) We need to undo the transformations in reverse or get weird results: boxView .animate(1) 
.scaleBy(0.5) .rotateBy(-0.5) .translateBy(-50, -50) .backgroundColor(.redColor()) License Fluent is under the MIT license.
"""

puts snippet(str,['swift','animat'])