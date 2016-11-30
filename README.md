# AmqpHelper

This is just an attempt to standardize and make more reusable some
of the AMQP code that I use in various pieces of the Medusa project,
e.g. in the collection registry and amazon backup.  

As such it may make certain assumptions that are true for these 
projects but not more generally, e.g. that it is running in the 
presence of Rails. These may or may not be removed at some point.
Also our usage is relatively simple and this is geared toward that
viewpoint.

We do hope to make this work with both MRI and JRuby though, as
we have code that runs under each. For starters it will be just MRI
though; code for JRuby will be added if and when needed. 