# Mailjet Integration for Preside

[![Build Status](https://travis-ci.org/pixl8/preside-ext-mailjet.svg?branch=stable)](https://travis-ci.org/pixl8/preside-ext-mailjet)

## Overview

This extension provides integration for [Mailjet](https://www.mailjet.com/) with Preside's email centre (Preside 10.8 and above).

Currently, the extension provides:

* A Message Centre service provider with configuration for sending email through mailjet's API
* A mailjet webhook endpoint (`/mailjet/hooks/`) for receiving and processing mailjet webhooks for delivery & bounce notifications, etc.

See the [wiki](https://github.com/pixl8/preside-ext-mailjet/wiki) for further documentation.

## Installation

From the root of your application, type the following command (using [CommandBox](https://www.ortussolutions.com/products/commandbox)):

```
box install preside-ext-mailjet
```

### Additional step for Preside 10.8 and below

If you are not already on Preside 10.9 or above, you'll need to enable the extension by opening up the Preside developer console and entering:

```
extension enable preside-ext-mailjet
reload all
```