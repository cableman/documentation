<?php
  @include $_SERVER['DOCUMENT_ROOT']. '/inc/head.inc';
?>
<body>
<div class="breakpoint-1">1 breakpoint active</div>
<div class="breakpoint-2">2 breakpoint active</div>
<div class="breakpoint-3">3 breakpoint active</div>
<div class="breakpoint-4">4 breakpoint active</div>
<header class="header" role="banner">
  <div class="header--inner">
    <a href="#top" class="logo--link"><img src="logo.png" alt="" class="logo--image"></a>
    <nav class="nav">
      <a href="#" title="Min konto" class="nav--link">
        <i class="icon-user"></i>
        <span class="nav--text">Min konto</span>
      </a>
      <a href="#" title="Notifikationer" class="nav--link-mail">
        <i class="icon-mail"></i>
        <span class="nav--text">Notifikationer</span>
        <span class="notification">3</span>
      </a>
      <a href="#" title="Menu" class="nav--link-menu">
        <i class="icon-menu"></i>
        <span class="nav--text">Menu</span>
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
        <input type="submit" class="search--button" value="Søg">
      </div>
    </form>
  </div>
</div>
</body>
</html>