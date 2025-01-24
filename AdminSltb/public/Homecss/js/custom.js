/*========================================================================
EXCLUSIVE ON themeforest.net
Template Name   : Prottasha - Bootstrap 4 Charity Landing Page
Author: ThemeAtelier
Created: September 2022
Last update: September 2022
========================================================================*/

/* TABLE OF CONTENTS
	1. PRELOADER
	2. ADD CLASS HEADER
	3. NAV COLLAPSE
	4. NAV SMOOTH SCROLL
	5. FIXED HEADER
	6. HERO SLIDER
	7. TEXT ANIMATION
	8. VIDEO LIGHTBOX
	9. CAUSES LIGHTBOX
	10. CAUSES PROGRESS BARS
	11. CAUSES SLIDER
	12. GALLERY FILTER
	13. GALLERY LIGHTBOX
	14. TESTIMONIAL SLIDER
	15. VOLUNTEERS SLIDER
	16. COUNTER UP JS
	17. CONTACT FORM
*/
var PATH = {};
(function ($) {
	"use strict"

	/******************** 1. PRELOADER ********************/
	PATH.preLoader = function () {
		$(".preloader").fadeOut();
			$("#preloader-wrap").delay(1000).fadeOut("slow");
	}

	/******************** 2. ADD CLASS HEADER ********************/
	PATH.HeaderSticky = function () {
		$(".navbar-toggler").on("click", function (a) {
			a.preventDefault(),
				$(".navbar").addClass("fixed-header")
		});
	}

	/******************** 3. NAV COLLAPSE ********************/
	PATH.MenuClose = function () {
		$('.navbar-nav .nav-link').on('click', function () {
			var toggle = $('.navbar-toggler').is(':visible');
			if (toggle) {
				$('.navbar-collapse').collapse('hide');
			}
		});
	}

	/******************** 4. NAV SMOOTH SCROLL ********************/
	PATH.HeaderScroll = function () {
		$('header a[href*="#"]:not([href="#"])').on('click', function () {
			var PathName = location.pathname.replace(/^\//, '') == this.pathname.replace(/^\//, '') || location.hostname == this.hostname;
			if (PathName) {
				var target = $(this.hash);
				target = target.length ? target : $('[name=' + this.hash.slice(1) + ']');
				if (target.length) {
					$('html,body').animate({
						scrollTop: target.offset().top - 65,
					}, 1000);
					return false;
				}
			}
		});
	}

	/******************** 5. FIXED HEADER ********************/
	PATH.HeaderFixed = function () {
		var varHeaderFix = $(window).scrollTop() >= 60,
		$navbar = $('.navbar');
		if (varHeaderFix) {
			$navbar.addClass('fixed-header');
		} else {
			$navbar.removeClass('fixed-header');
		}
	}
	/******************** 6. HERO SLIDER  ********************/
	PATH.heroSlider = function(){
		var swiper = new Swiper('.hero-swiper', {
			speed: 3000,
			autoplay: {
			delay: 10000,
			},
			navigation: {
				nextEl: '.swiper-button-next',
				prevEl: '.swiper-button-prev',
			},
			pagination: {
			el: '.swiper-pagination',
			clickable: true,
			},
			});
		}

	/******************** 7. TEXT ANIMATION ********************/
	PATH.textAnimation = function () {
		var $tlt1 = $('.tlt1'),
			$tlt = $('.tlt');
			
		if( $tlt1.length ){
			$tlt1.textillate({
				loop: true,
				in: {
					effect: 'fadeInDown',
				},
				out: {
					effect: 'flip',
				},
			});
		}
		//
		if( $tlt.length ){
			$tlt.textillate({
				loop: true,
				in: {
					effect: 'fadeInRight',
				},
				out: {
					effect: 'fadeOutLeft',
				},
			});
		}
	}

	/******************** 8. VIDEO LIGHTBOX ********************/
	PATH.videoModal = function () {
		var $jsmodal = $(".js-modal-btn");
		if ($jsmodal.length) {
			$jsmodal.modalVideo();
		}
	}

	/******************** 9. CAUSES LIGHTBOX ********************/
	PATH.causesLightBox = function () {
	var $causesLightBox = $('.causes-lightbox');
	if ($causesLightBox.length) {
		$causesLightBox.magnificPopup({
			type: 'image',
			mainClass: 'mfp-fade',
			removalDelay: 160,
			fixedContentPos: true
		});
	}
}
	/******************** 10. CAUSES PROGRESS BARS ********************/
	PATH.causesProgress = function(){
		var $skills = $('.content-box'),
		$skillProgressBars = $skills.find('.progress-bars');
	
	if ($skillProgressBars.length) {
		$skillProgressBars.find('.progress-bar').each(function () {
			var $t = $(this);
	
			$t.css('width', 0);
	
			$t.waypoint(function () {
				$t.css('width', $t.data('value') + '%');
			}, {
				triggerOnce: true,
				offset: 'bottom-in-view'
			});
		});
	}
	}

	/******************** 11. CAUSES SLIDER ********************/
	PATH.causesSlider = function(){
	var cswiper = new Swiper('.causes-swiper', {
	slidesPerView: 3,
	spaceBetween: 0,
	freeMode: true,
	pagination: {
	  el: '.swiper-pagination',
	  clickable: true,
	},
	breakpoints: {
        1199: {
          slidesPerView: 2,
        },
        768: {
          slidesPerView: 1,
        },
        640: {
          slidesPerView: 1,
        },
        320: {
          slidesPerView: 1,
        }
      }
	});
	}
	
	/******************** 12. GALLERY FILTER ********************/
		PATH.GalleryFilter = function () {
		var $portfolio_selectors = $('.gallery-filter >li>a');
		if ($portfolio_selectors.length) {
			var $portfolio = $('.gallery-boxes');
			$portfolio.isotope({
				itemSelector: '.gallery-box',
				layoutMode: 'fitRows'
			});
			$portfolio_selectors.on('click', function () {
				$portfolio_selectors.removeClass('active');
				$(this).addClass('active');
				var selector = $(this).attr('data-filter');
				$portfolio.isotope({
					filter: selector
				});
				return false;
			});
		}
	}

	/******************** 13. GALLERY LIGHTBOX ********************/
	PATH.GalleryLightBox = function () {
	var $galleryLightBox = $('.light-icon');
	if ($galleryLightBox.length) {
		$galleryLightBox.magnificPopup({
			type: 'image',
			mainClass: 'mfp-fade',
			removalDelay: 160,
			fixedContentPos: true,
			delegate: 'a',
			gallery: {
				enabled: true
			}
		});
	}
	}

	/******************** 14. TESTIMONIAL SLIDER ********************/
	PATH.sliderTestimonial = function () {
	var vswiper = new Swiper('.testimonialSwiper', {
	speed: 2000,
	autoplay: {
	  delay: 2000,
	},
	pagination: {
	  el: '.swiper-pagination',
	  clickable: true,
	},
	});
	}
	/******************** 15. VOLUNTEERS SLIDER ********************/
	PATH.sliderVolunteers = function () {
	var vswiper = new Swiper('.volunteers-swiper', {
	slidesPerView: 4,
	spaceBetween: 0,
	freeMode: true,
	pagination: {
	  el: '.swiper-pagination',
	  clickable: true,
	},
	breakpoints: {
		1199: {
			slidesPerView: 3,
		},
        1024: {
          slidesPerView: 2,
        },
        768: {
          slidesPerView: 2,
        },
        640: {
          slidesPerView: 1,
        },
        320: {
          slidesPerView: 1,
        }
      }
	});
	}
	/******************** 16. COUNTER UP JS ********************/
	PATH.counterUp = function () {
	var $counter = $('.counter');
	if ($counter.length) {
		$counter.counterUp({
			delay: 10,
			time: 3000
		});
	}
	}

	/******************** 17. CONTACT FORM ********************/
	PATH.contactForm = function () {
	function isValidEmail(emailAddress) {
		var pattern = new RegExp(/^(("[\w-\s]+")|([\w-]+(?:\.[\w-]+)*)|("[\w-\s]+")([\w-]+(?:\.[\w-]+)*))(@((?:[\w-]+\.)*\w[\w-]{0,66})\.([a-z]{2,6}(?:\.[a-z]{2})?)$)|(@\[?((25[0-5]\.|2[0-4][0-9]\.|1[0-9]{2}\.|[0-9]{1,2}\.))((25[0-5]|2[0-4][0-9]|1[0-9]{2}|[0-9]{1,2})\.){2}(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[0-9]{1,2})\]?$)/i);
		return pattern.test(emailAddress);
	};
	var $contact = $("#contact-form");
	if ($contact.length) {
		$contact.on('submit', function (e) {
			e.preventDefault();
			var success = $(this).find('.email-success'),
				failed = $(this).find('.email-failed'),
				loader = $(this).find('.email-loading'),
				postUrl = $(this).attr('action');
			var data = {
				name: $(this).find('.contact-name').val(),
				email: $(this).find('.contact-email').val(),
				subject: $(this).find('.contact-subject').val(),
				message: $(this).find('.contact-message').val()
			};
			if (isValidEmail(data['email']) && (data['message'].length > 1) && (data['name'].length > 1)) {
				$.ajax({
					type: "POST",
					url: postUrl,
					data: data,
					beforeSend: function () {
						loader.fadeIn(1000);
					},
					success: function (data) {
						loader.fadeOut(1000);
						success.delay(500).fadeIn(1000);
						failed.fadeOut(500);
					},
					error: function (xhr) { // if error occured
						loader.fadeOut(1000);
						failed.delay(500).fadeIn(1000);
						success.fadeOut(500);
					},
					complete: function () {
						loader.fadeOut(1000);
					}
				});
			} else {
				loader.fadeOut(1000);
				failed.delay(500).fadeIn(1000);
				success.fadeOut(500);
			}
			return false;
		});
	}
	}

/* Document ready function */
	$(function(){
		PATH.textAnimation(),
		PATH.MenuClose(),
		PATH.HeaderScroll(),
		PATH.HeaderSticky();
		PATH.videoModal();
		PATH.causesLightBox();
		PATH.causesProgress();
		PATH.GalleryLightBox();
		PATH.contactForm();
	});

/* Window on scroll function */
	$(window).on("scroll", function () {
		PATH.HeaderFixed();
	});

/* Window on load function */
$(window).on('load', function () {
	PATH.sliderTestimonial();
	PATH.sliderVolunteers();
	PATH.heroSlider();
	PATH.causesSlider();
	PATH.GalleryFilter();
	PATH.counterUp();
	PATH.preLoader();
});

})(jQuery);