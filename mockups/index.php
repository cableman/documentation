<?php
  @include $_SERVER['DOCUMENT_ROOT']. '/inc/head.inc';
?>
<body>
<div class="first-breakpoint">First breakpoint active</div>
<div class="second-breakpoint">Second breakpoint active</div>
<header class="header" role="banner">
  <div class="header--inner">
    <a href="#top" class="logo--link"><img src="logo.png" alt="" class="logo--image"></a>
    <nav class="responsive-nav">
      <a href="#" title="Min konto" class="responsive-nav--link">
        <i class="icon-user"></i>
        <span class="is-hidden">Min konto</span>
      </a>
      <a href="#" title="Notifikationer" class="responsive-nav--link-mail">
        <i class="icon-mail"></i>
        <span class="is-hidden">Notifikationer</span>
        <span class="notification">3</span>
      </a>
      <a href="#" title="Menu" class="responsive-nav--link-menu">
        <i class="icon-menu"></i>
        <span class="is-hidden">Menu</span>
      </a>
    </nav>
  </div>
</header>
<div class="search">
  <div class="search--inner">
    <form>
      <label class="form-label">Søg efter svar</label>
      <div class="search--field-wrapper">
        <i class="search--icon icon-search"></i>
        <input type="text" placeholder="Skriv f.eks. hvordan støvsuger man" class="search--field">
      </div>
      <input type="submit" class="button--action" value="Søg">
    </form>
  </div>
</div>
</body>
</html>