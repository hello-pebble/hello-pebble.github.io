---
layout: default
title: Resume
---

# 이력서

<div class="contact-links">
  <a href="mailto:kwdk2323@gamil.com" title="Email">
    <svg class="icon" viewBox="0 0 24 24" width="24" height="24"><path fill="currentColor" d="M20 4H4c-1.1 0-1.99.9-1.99 2L2 18c0 1.1.9 2 2 2h16c1.1 0 2-.9 2-2V6c0-1.1-.9-2-2-2zm0 4l-8 5-8-5V6l8 5 8-5v2z"/></svg>
    your-email@example.com
  </a>
  <a href="https://github.com/hello-pebble" target="_blank" title="GitHub">
    <svg class="icon" viewBox="0 0 24 24" width="24" height="24"><path fill="currentColor" d="M12 2C6.477 2 2 6.477 2 12c0 4.419 2.865 8.166 6.839 9.489.5.092.682-.217.682-.482 0-.237-.008-.866-.013-1.7-2.782.604-3.369-1.34-3.369-1.34-.454-1.156-1.11-1.463-1.11-1.463-.908-.62.069-.608.069-.608 1.003.07 1.531 1.03 1.531 1.03.892 1.529 2.341 1.087 2.91.832.092-.647.35-1.088.636-1.338-2.22-.253-4.555-1.11-4.555-4.943 0-1.091.39-1.984 1.029-2.683-.103-.253-.446-1.27.098-2.647 0 0 .84-.269 2.75 1.025A9.564 9.564 0 0112 6.844c.85.004 1.705.115 2.504.337 1.909-1.294 2.747-1.025 2.747-1.025.546 1.377.203 2.394.1 2.647.64.699 1.028 1.592 1.028 2.683 0 3.842-2.339 4.687-4.566 4.935.359.309.678.92.678 1.855 0 1.338-.012 2.419-.012 2.747 0 .268.18.58.688.482C19.138 20.161 22 16.416 22 12c0-5.523-4.477-10-10-10z"/></svg>
    GitHub
  </a>
  <a href="https://github.com/hello-pebble/wiki" target="_blank" title="GitWiki">
    <svg class="icon" viewBox="0 0 24 24" width="24" height="24"><path fill="currentColor" d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm1 15h-2v-6h2v6zm0-8h-2V7h2v2z"/></svg>
    GitWiki
  </a>
</div>

<style>
.contact-links {
  display: flex;
  gap: 20px;
  margin: 20px 0;
  flex-wrap: wrap;
}
.contact-links a {
  display: flex;
  align-items: center;
  gap: 8px;
  text-decoration: none;
  color: var(--text-color);
  font-weight: 500;
  transition: opacity 0.3s;
}
.contact-links a:hover {
  opacity: 0.7;
}
.icon {
  color: var(--text-color);
}
</style>

---

{% highlight ruby %} def print_hi(name) puts "Hi, #{name}" end print_hi('Tom') #=> prints 'Hi, Tom' to STDOUT. {% endhighlight %}

Check out the Jekyll docs for more info on how to get the most out of Jekyll.
