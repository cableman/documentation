<?php
  @include $_SERVER['DOCUMENT_ROOT']. '/inc/head.inc';
?>
<body>
<?php
  @include $_SERVER['DOCUMENT_ROOT']. '/inc/breakpoint_debug.inc';
?>
<header class="header" role="banner">
  <div class="header--inner">
    <a href="/" class="logo--link"><img src="logo.png" alt="" class="logo--image"></a>
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
        <input type="text" placeholder="Skriv f.eks. &quot;Hvordan dokumenteres delvis aktindsigt&quot;" class="search--field">
        <input type="submit" class="search--button" value="Søg">
      </div>
    </form>
  </div>
</div>
<div class="question">
  <div class="question--inner">
    <h1><strong>Spørgsmål:</strong> Hvordan dokumenteres delvis aktindsigt? Og findes der en vejledning i dokumentation af aktindsigt?</h1>
    <ul class="content-list">
      <li class="content-list--item">
        <span class="question--answer">Bedste svar:</span> Nej der er ikke en selvstændig vejledning i aktindsigt. Under aktindsigt (i Stamdata) kan Status sættes til Delvis bevilliget samt i bemærkningen kan dokumenteres hvilken sag det omfatter.
      </li>
      <li class="content-list--item is-last">
        Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book.
      </li>
    </ul>
  </div>
</div>
</body>
</html>