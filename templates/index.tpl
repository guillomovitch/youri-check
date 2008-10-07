[% INCLUDE header.tpl title = 'QA reports' %]

[% IF tests %]
    <h2>Global reports</h2>
    [% FOREACH test = tests %]
	<li>
	    <a href="report.cgi?test=[% test.name %]">[% test.name %]</a>
	    ([% test.count %])
	</li>
    [% END %]
[% END %]

[% IF maintainers %]
    <h2>Individual reports</h2>
    <ul>
    [% FOREACH maintainer = maintainers %]
	<li><a href="report.cgi?maintainer=[% maintainer.name %]">[% maintainer.name %]</a></li>
    [% END %]
[% END %]
</ul>

[% INCLUDE footer.tpl %]
