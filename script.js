// Smooth scrolling to sections
function scrollToSection(sectionId) {
    const element = document.getElementById(sectionId);
    if (element) {
        element.scrollIntoView({ behavior: 'smooth' });
    }
}

// Hamburger menu functionality
const hamburger = document.querySelector('.hamburger');
const navLinks = document.querySelector('.nav-links');

if (hamburger) {
    hamburger.addEventListener('click', () => {
        navLinks.style.display = navLinks.style.display === 'flex' ? 'none' : 'flex';
        navLinks.style.position = 'absolute';
        navLinks.style.top = '60px';
        navLinks.style.left = '0';
        navLinks.style.width = '100%';
        navLinks.style.flexDirection = 'column';
        navLinks.style.backgroundColor = 'rgba(15, 23, 42, 0.95)';
        navLinks.style.padding = '1rem';
        navLinks.style.gap = '1rem';
    });
}

// Pie Chart using Canvas for Revenue Split
function drawPieChart() {
    const canvas = document.getElementById('splitChart');
    if (!canvas) return;

    const ctx = canvas.getContext('2d');
    const width = canvas.parentElement.clientWidth;
    const height = Math.min(width, 400);
    canvas.width = width;
    canvas.height = height;

    const centerX = width / 2;
    const centerY = height / 2;
    const radius = Math.min(width, height) / 2 - 20;

    // Community (90%) - Purple
    drawSlice(ctx, centerX, centerY, radius, 0, Math.PI * 1.8, '#7851A9');
    // Developers (10%) - Green
    drawSlice(ctx, centerX, centerY, radius, Math.PI * 1.8, Math.PI * 2, '#00FF00');

    // Draw labels
    drawLabel(ctx, centerX, centerY, radius, Math.PI * 0.9, '90%\nCommunity', '#FFFFFF');
    drawLabel(ctx, centerX, centerY, radius, Math.PI * 1.9, '10%\nDevs', '#FFFFFF');
}

function drawSlice(ctx, centerX, centerY, radius, startAngle, endAngle, color) {
    ctx.fillStyle = color;
    ctx.beginPath();
    ctx.arc(centerX, centerY, radius, startAngle, endAngle);
    ctx.lineTo(centerX, centerY);
    ctx.fill();

    // Blue border
    ctx.strokeStyle = '#00BFFF';
    ctx.lineWidth = 3;
    ctx.beginPath();
    ctx.arc(centerX, centerY, radius, startAngle, endAngle);
    ctx.lineTo(centerX, centerY);
    ctx.stroke();
}

function drawLabel(ctx, centerX, centerY, radius, angle, text, color) {
    const labelRadius = radius * 0.65;
    const x = centerX + Math.cos(angle) * labelRadius;
    const y = centerY + Math.sin(angle) * labelRadius;

    ctx.fillStyle = color;
    ctx.font = 'bold 20px Segoe UI, sans-serif';
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';

    const lines = text.split('\n');
    lines.forEach((line, index) => {
        ctx.fillText(line, x, y + (index - (lines.length - 1) / 2) * 24);
    });
}

// Initialize pie chart when page loads
window.addEventListener('DOMContentLoaded', drawPieChart);
window.addEventListener('resize', drawPieChart);

// Form submission handling
const waitlistForm = document.getElementById('waitlistForm');
if (waitlistForm) {
    waitlistForm.addEventListener('submit', (e) => {
        e.preventDefault();

        const formData = new FormData(waitlistForm);
        const inputs = waitlistForm.querySelectorAll('input');
        const formValues = {};

        inputs.forEach(input => {
            formValues[input.placeholder] = input.value;
        });

        // Show success message
        const button = waitlistForm.querySelector('button');
        const originalText = button.textContent;

        button.textContent = '✓ Success! Check your email';
        button.style.background = 'linear-gradient(135deg, #14f195 0%, #00d966 100%)';

        // Reset form after delay
        setTimeout(() => {
            waitlistForm.reset();
            button.textContent = originalText;
            button.style.background = '';
        }, 3000);

        console.log('Waitlist submission:', formValues);
    });
}

// Navbar scroll effect
let lastScrollTop = 0;
const navbar = document.querySelector('.navbar');

window.addEventListener('scroll', () => {
    const scrollTop = window.pageYOffset || document.documentElement.scrollTop;

    if (scrollTop > 100) {
        navbar.style.borderBottomColor = 'rgba(20, 241, 149, 0.2)';
    } else {
        navbar.style.borderBottomColor = 'rgb(51, 65, 85)';
    }

    lastScrollTop = scrollTop;
});

// Intersection Observer for fade-in animations
const observerOptions = {
    threshold: 0.1,
    rootMargin: '0px 0px -50px 0px'
};

const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
        if (entry.isIntersecting) {
            entry.target.style.opacity = '1';
            entry.target.style.transform = 'translateY(0)';
        }
    });
}, observerOptions);

// Observe all feature cards and timeline items
document.querySelectorAll('.feature-card, .timeline-item, .split-item').forEach(el => {
    el.style.opacity = '0';
    el.style.transform = 'translateY(20px)';
    el.style.transition = 'opacity 0.6s ease, transform 0.6s ease';
    observer.observe(el);
});

// Animated counter for statistics
function animateCounter(element, target, duration = 2000) {
    let current = 0;
    const increment = target / (duration / 16);
    const interval = setInterval(() => {
        current += increment;
        if (current >= target) {
            element.textContent = target;
            clearInterval(interval);
        } else {
            element.textContent = Math.floor(current);
        }
    }, 16);
}

// Add glow effect on mouse move for hero section
const heroSection = document.querySelector('.hero');
if (heroSection) {
    heroSection.addEventListener('mousemove', (e) => {
        const x = e.clientX;
        const y = e.clientY;

        const cards = document.querySelectorAll('.floating-card');
        cards.forEach(card => {
            const cardRect = card.getBoundingClientRect();
            const cardCenterX = cardRect.left + cardRect.width / 2;
            const cardCenterY = cardRect.top + cardRect.height / 2;

            const angle = Math.atan2(y - cardCenterY, x - cardCenterX);
            const distance = 50;

            card.style.transform = `translate(${Math.cos(angle) * distance}px, ${Math.sin(angle) * distance}px)`;
        });
    });
}

// Typing effect for hero title
function typeEffect(element, text, speed = 100) {
    let index = 0;
    element.textContent = '';

    function type() {
        if (index < text.length) {
            element.textContent += text.charAt(index);
            index++;
            setTimeout(type, speed);
        }
    }

    type();
}

// Initialize on load
window.addEventListener('DOMContentLoaded', () => {
    // Add subtle animations to buttons on hover
    const buttons = document.querySelectorAll('.btn');
    buttons.forEach(btn => {
        btn.addEventListener('mouseenter', function() {
            this.style.letterSpacing = '2px';
        });
        btn.addEventListener('mouseleave', function() {
            this.style.letterSpacing = '1px';
        });
    });
});

// Parallax effect on scroll
window.addEventListener('scroll', () => {
    const scrolled = window.pageYOffset;
    const stars = document.querySelector('.stars');
    if (stars) {
        stars.style.transform = `translateY(${scrolled * 0.5}px)`;
    }
});
